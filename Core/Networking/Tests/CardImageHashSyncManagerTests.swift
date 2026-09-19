@testable import Networking
import Foundation
import Testing

struct CardImageHashSyncManagerTests {
  private let baseURL = URL(string: "https://example.test/db")!

  /// Serves canned files by name and records which ones were requested.
  private actor StubServer {
    var files: [String: Data]
    private(set) var requested: [String] = []

    init(files: [String: Data]) { self.files = files }

    func load(_ url: URL) throws -> (Data, URLResponse) {
      requested.append(url.lastPathComponent)
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
    directory: URL? = nil
  ) throws -> Harness {
    let directory = directory ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Self.encode(localDatabase).write(to: directory.appendingPathComponent("MTG_Hashes_Compressed.lzfse"))
    try localManifest?.write(to: directory.appendingPathComponent("manifest.json"))
    return makeHarness(directory: directory, serverFiles: serverFiles)
  }

  private func makeHarness(directory: URL, serverFiles: [String: Data]) -> Harness {
    let server = StubServer(files: serverFiles)
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

  @Test func bestMatches_shouldReturnTheNearestFacesWithinTheThreshold() async throws {
    let dictionary: [String: Data] = [
      "exact": try FeaturePrintArchiveFixture.archive([1, 0, 0, 0]),
      "near": try FeaturePrintArchiveFixture.archive([0.5, 0, 0, 0]),
      "far": try FeaturePrintArchiveFixture.archive([0, 0, 0, 1]),
    ]
    let plist = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
    let index = try await CardFeaturePrintIndex.decoding(plist)
    let expected = [MatchResult(id: "exact", distance: 0), MatchResult(id: "near", distance: 0.25)]

    #expect(await index.bestMatches(for: [1, 0, 0, 0]) == expected)
    #expect(await index.compressedForSearch().bestMatches(for: [1, 0, 0, 0]) == expected)
  }

  @Test func bestMatches_whenShortlistingFromTheStoredCompressedCopy_shouldFindTheFace() async throws {
    // 1,000 faces of 256 numbers that vary along 10 directions, so the 128
    // compressed directions capture them and the 200-face shortlist is a fifth of them.
    let dimension = 256, faceCount = 1_000
    let basis = (0..<10).map { k in (0..<dimension).map { Float(sin(Double($0 * (k + 1)) * 0.37)) } }
    let faces = (0..<faceCount).map { face in
      (0..<dimension).map { j in
        (0..<10).reduce(Float(0)) { sum, k in sum + Float(cos(Double(face * 31 + k * 17))) * basis[k][j] }
      }.map { Float(Float16($0)) }
    }
    let vectors = faces.flatMap { $0.map { Float16($0) } }.withUnsafeBytes { Data($0) }
    let index = await CardFeaturePrintIndex(ids: faces.indices.map(String.init), dimension: dimension, vectors: vectors)
      .compressedForSearch()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try index.write(to: url)

    let stored = try CardFeaturePrintIndex(contentsOf: url)

    #expect(stored.shortlistDimension == 128)
    for face in [0, 123, 999] {
      #expect(await stored.bestMatches(for: faces[face]).first == MatchResult(id: String(face), distance: 0))
    }
  }
}
