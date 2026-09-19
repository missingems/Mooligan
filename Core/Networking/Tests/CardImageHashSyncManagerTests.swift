@testable import Networking
import Foundation
import Testing

struct CardImageHashSyncManagerTests {
  private let baseURL = URL(string: "https://example.test/db")!

  /// Serves canned files by name and records which ones were requested.
  private actor StubServer {
    var files: [String: Data]
    let manifestDelay: Duration
    private(set) var requested: [String] = []

    init(files: [String: Data], manifestDelay: Duration = .zero) {
      self.files = files
      self.manifestDelay = manifestDelay
    }

    func load(_ url: URL) async throws -> (Data, URLResponse) {
      requested.append(url.lastPathComponent)
      if url.lastPathComponent == "manifest.json" { try await Task.sleep(for: manifestDelay) }
      let data = files[url.lastPathComponent]
      let response = HTTPURLResponse(url: url, statusCode: data == nil ? 404 : 200, httpVersion: nil, headerFields: nil)!
      return (data ?? Data(), response)
    }
  }

  private struct Harness {
    let manager: CardImageHashSyncManager
    let server: StubServer
    let directory: URL

    var indexURL: URL { directory.appendingPathComponent("MTG_Hashes.index") }
    var legacyDatabaseURL: URL { directory.appendingPathComponent("MTG_Hashes_Compressed.lzfse") }
    var legacyManifestURL: URL { directory.appendingPathComponent("manifest.json") }

    /// Each stored face's version, which the tests keep in its vector's first element.
    func localDatabase() throws -> [String: Float] {
      let index = try CardFeaturePrintIndex(contentsOf: indexURL)
      return index.vectors.withUnsafeBytes { vectors in
        Dictionary(uniqueKeysWithValues: index.ids.enumerated().map { row, id in
          let bits = vectors.loadUnaligned(fromByteOffset: row * index.dimension * 2, as: UInt16.self)
          return (id, Float(Float16(bitPattern: bits)))
        })
      }
    }

    func localIndex() throws -> CardFeaturePrintIndex {
      try CardFeaturePrintIndex(contentsOf: indexURL)
    }
  }

  /// A database file in the server's format; each face's vector is `[version, 0, 0, 0]`.
  private static func encode(_ entries: [String: Float]) throws -> Data {
    let dictionary = try entries.mapValues { try FeaturePrintArchiveFixture.archive([$0, 0, 0, 0]) }
    let plist = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
    return try (plist as NSData).compressed(using: .lzfse) as Data
  }

  private static func manifest(_ masterVersion: String, chunks: Int, patch: Int) throws -> Data {
    try JSONEncoder().encode(CardHashDatabaseManifest(masterVersion: masterVersion, masterChunks: chunks, latestPatch: patch))
  }

  /// Seeds the files the previous format kept, so every test also covers
  /// converting them on first launch.
  private func makeHarness(
    localDatabase: [String: Float],
    localManifest: Data? = nil,
    serverFiles: [String: Data],
    manifestDelay: Duration = .zero,
    directory: URL? = nil
  ) throws -> Harness {
    let directory = directory ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Self.encode(localDatabase).write(to: directory.appendingPathComponent("MTG_Hashes_Compressed.lzfse"))
    try localManifest?.write(to: directory.appendingPathComponent("manifest.json"))
    return makeHarness(directory: directory, serverFiles: serverFiles, manifestDelay: manifestDelay)
  }

  private func makeHarness(directory: URL, serverFiles: [String: Data], manifestDelay: Duration = .zero) -> Harness {
    let server = StubServer(files: serverFiles, manifestDelay: manifestDelay)
    let manager = CardImageHashSyncManager(
      baseURL: baseURL.absoluteString,
      documentsDirectory: directory,
      loadData: { try await server.load($0) }
    )
    return Harness(manager: manager, server: server, directory: directory)
  }

  @Test func whenThereIsNoLocalManifest_shouldReplaceTheDatabaseWithTheFullMaster() async throws {
    let harness = try makeHarness(
      localDatabase: ["a": 1],
      serverFiles: [
        "manifest.json": try Self.manifest("m1", chunks: 2, patch: 3),
        "MTG_Hashes_Master_0.lzfse": try Self.encode(["a": 2]),
        "MTG_Hashes_Master_1.lzfse": try Self.encode(["b": 2]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": 2, "b": 2])
    #expect(try harness.localIndex().latestPatch == 3)
    #expect(await harness.server.requested.contains { $0.hasPrefix("patch_") } == false)
  }

  @Test func whenAMasterChunkIsMissing_shouldKeepTheLocalDatabase() async throws {
    let harness = try makeHarness(
      localDatabase: ["a": 1],
      serverFiles: [
        "manifest.json": try Self.manifest("m1", chunks: 2, patch: 0),
        "MTG_Hashes_Master_0.lzfse": try Self.encode(["a": 2]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": 1])
    #expect(try harness.localIndex().masterVersion == nil)
  }

  @Test func whenOnTheSameMaster_shouldApplyOnlyTheNewPatchesInOrder() async throws {
    let harness = try makeHarness(
      localDatabase: ["a": 1, "b": 1],
      localManifest: try Self.manifest("m1", chunks: 2, patch: 1),
      serverFiles: [
        "manifest.json": try Self.manifest("m1", chunks: 2, patch: 3),
        "patch_2.lzfse": try Self.encode(["a": 2, "c": 2]),
        "patch_3.lzfse": try Self.encode(["a": 3]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": 3, "b": 1, "c": 2])
    #expect(try harness.localIndex().latestPatch == 3)
    // Patches download together, so only the set of requests is fixed.
    #expect(await harness.server.requested.sorted() == ["manifest.json", "patch_2.lzfse", "patch_3.lzfse"])
  }

  @Test func whenAPatchIsMissing_shouldNotAdvanceThePatchLevel() async throws {
    let harness = try makeHarness(
      localDatabase: ["a": 1],
      localManifest: try Self.manifest("m1", chunks: 2, patch: 1),
      serverFiles: [
        "manifest.json": try Self.manifest("m1", chunks: 2, patch: 3),
        "patch_2.lzfse": try Self.encode(["a": 2]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": 1])
    #expect(try harness.localIndex().latestPatch == 1)
  }

  @Test func whenTheServerRebased_shouldDownloadTheNewMaster() async throws {
    let harness = try makeHarness(
      localDatabase: ["a": 1, "gone": 1],
      localManifest: try Self.manifest("m1", chunks: 1, patch: 5),
      serverFiles: [
        "manifest.json": try Self.manifest("m2", chunks: 1, patch: 0),
        "MTG_Hashes_Master_0.lzfse": try Self.encode(["a": 2]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": 2])
    #expect(try harness.localIndex().masterVersion == "m2")
  }

  @Test func whenAlreadyCurrent_shouldOnlyFetchTheManifest() async throws {
    let manifest = try Self.manifest("m1", chunks: 2, patch: 4)
    let harness = try makeHarness(
      localDatabase: ["a": 4],
      localManifest: manifest,
      serverFiles: ["manifest.json": manifest]
    )

    await harness.manager.sync()

    #expect(await harness.server.requested == ["manifest.json"])
    #expect(try harness.localDatabase() == ["a": 4])
  }

  @Test func whenTheOldFormatIsConverted_shouldRemoveItAndKeepItsPatchLevelOnTheNextLaunch() async throws {
    let manifest = try Self.manifest("m1", chunks: 2, patch: 4)
    let firstLaunch = try makeHarness(
      localDatabase: ["a": 4],
      localManifest: manifest,
      serverFiles: ["manifest.json": manifest]
    )
    await firstLaunch.manager.sync()

    #expect(FileManager.default.fileExists(atPath: firstLaunch.legacyDatabaseURL.path) == false)
    #expect(FileManager.default.fileExists(atPath: firstLaunch.legacyManifestURL.path) == false)

    let nextLaunch = makeHarness(directory: firstLaunch.directory, serverFiles: ["manifest.json": manifest])
    await nextLaunch.manager.sync()

    #expect(await nextLaunch.server.requested == ["manifest.json"])
    #expect(try nextLaunch.localDatabase() == ["a": 4])
  }

  @Test func whenSavingFails_shouldKeepTheConvertedDatabaseForTheSessionWithoutDownloadingTheMaster() async throws {
    let manifest = try Self.manifest("m1", chunks: 1, patch: 4)
    let harness = try makeHarness(
      localDatabase: ["a": 4],
      localManifest: manifest,
      serverFiles: [
        "manifest.json": manifest,
        "MTG_Hashes_Master_0.lzfse": try Self.encode(["a": 5]),
      ]
    )
    // Given a directory nothing can be written to, like a full disk.
    try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: harness.directory.path)
    defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: harness.directory.path) }

    // When the scanner opens twice.
    await harness.manager.sync()
    await harness.manager.sync()

    // Then the converted database serves both, at its own patch level.
    #expect(await harness.manager.isReady)
    #expect(await harness.server.requested == ["manifest.json", "manifest.json"])
    #expect(FileManager.default.fileExists(atPath: harness.legacyDatabaseURL.path))
  }

  @Test func whenSyncsOverlap_shouldRunOnce() async throws {
    let manifest = try Self.manifest("m1", chunks: 2, patch: 4)
    let harness = try makeHarness(
      localDatabase: ["a": 4],
      localManifest: manifest,
      serverFiles: ["manifest.json": manifest],
      manifestDelay: .milliseconds(200)
    )

    // When the scanner opens again while the first sync is still running.
    async let first: Void = harness.manager.sync()
    async let second: Void = harness.manager.sync()
    _ = await (first, second)

    #expect(await harness.server.requested == ["manifest.json"])
  }

  @Test func whenTheOldDatabaseHoldsNoFeaturePrints_shouldDownloadTheMaster() async throws {
    let manifest = try Self.manifest("m1", chunks: 1, patch: 4)
    let harness = try makeHarness(
      localDatabase: [:],
      localManifest: manifest,
      serverFiles: [
        "manifest.json": manifest,
        "MTG_Hashes_Master_0.lzfse": try Self.encode(["a": 4]),
      ]
    )
    // Given an old database whose entries aren't archived feature prints.
    let junk = try PropertyListSerialization.data(fromPropertyList: ["a": Data("junk".utf8)], format: .binary, options: 0)
    try ((junk as NSData).compressed(using: .lzfse) as Data).write(to: harness.legacyDatabaseURL)

    await harness.manager.sync()

    // Then it isn't taken as current at patch 4; the master replaces it.
    #expect(await harness.server.requested.contains("MTG_Hashes_Master_0.lzfse"))
    #expect(try harness.localDatabase() == ["a": 4])
  }
}
