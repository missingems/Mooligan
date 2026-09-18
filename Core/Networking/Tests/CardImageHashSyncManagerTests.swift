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

    var databaseURL: URL { directory.appendingPathComponent("MTG_Hashes_Compressed.lzfse") }
    var manifestURL: URL { directory.appendingPathComponent("manifest.json") }

    func localDatabase() throws -> [String: String] {
      try decode(Data(contentsOf: databaseURL))
    }

    func localManifest() throws -> CardHashDatabaseManifest? {
      guard let data = try? Data(contentsOf: manifestURL) else { return nil }
      return try JSONDecoder().decode(CardHashDatabaseManifest.self, from: data)
    }
  }

  private static func encode(_ entries: [String: String]) throws -> Data {
    let dictionary = entries.mapValues { Data($0.utf8) }
    let plist = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
    return try (plist as NSData).compressed(using: .lzfse) as Data
  }

  private static func decode(_ data: Data) throws -> [String: String] {
    let plist = try (data as NSData).decompressed(using: .lzfse) as Data
    let dictionary = try #require(
      try PropertyListSerialization.propertyList(from: plist, options: [], format: nil) as? [String: Data]
    )
    return dictionary.mapValues { String(decoding: $0, as: UTF8.self) }
  }

  private static func manifest(_ masterVersion: String, chunks: Int, patch: Int) throws -> Data {
    try JSONEncoder().encode(CardHashDatabaseManifest(masterVersion: masterVersion, masterChunks: chunks, latestPatch: patch))
  }

  private func makeHarness(
    localDatabase: [String: String],
    localManifest: Data? = nil,
    serverFiles: [String: Data]
  ) throws -> Harness {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try Self.encode(localDatabase).write(to: directory.appendingPathComponent("MTG_Hashes_Compressed.lzfse"))
    try localManifest?.write(to: directory.appendingPathComponent("manifest.json"))

    let server = StubServer(files: serverFiles)
    let manager = CardImageHashSyncManager(
      baseURL: baseURL.absoluteString,
      documentsDirectory: directory,
      loadData: { try await server.load($0) }
    )
    return Harness(manager: manager, server: server, directory: directory)
  }

  @Test func whenThereIsNoLocalManifest_shouldReplaceTheDatabaseWithTheFullMaster() async throws {
    let remoteManifest = try Self.manifest("m1", chunks: 2, patch: 3)
    let harness = try makeHarness(
      localDatabase: ["a": "bundled"],
      serverFiles: [
        "manifest.json": remoteManifest,
        "MTG_Hashes_Master_0.lzfse": try Self.encode(["a": "current"]),
        "MTG_Hashes_Master_1.lzfse": try Self.encode(["b": "current"]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": "current", "b": "current"])
    #expect(try harness.localManifest()?.latestPatch == 3)
    #expect(await harness.server.requested.contains { $0.hasPrefix("patch_") } == false)
  }

  @Test func whenAMasterChunkIsMissing_shouldKeepTheLocalDatabase() async throws {
    let harness = try makeHarness(
      localDatabase: ["a": "bundled"],
      serverFiles: [
        "manifest.json": try Self.manifest("m1", chunks: 2, patch: 0),
        "MTG_Hashes_Master_0.lzfse": try Self.encode(["a": "current"]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": "bundled"])
    #expect(try harness.localManifest() == nil)
  }

  @Test func whenOnTheSameMaster_shouldApplyOnlyTheNewPatchesInOrder() async throws {
    let harness = try makeHarness(
      localDatabase: ["a": "v1", "b": "v1"],
      localManifest: try Self.manifest("m1", chunks: 2, patch: 1),
      serverFiles: [
        "manifest.json": try Self.manifest("m1", chunks: 2, patch: 3),
        "patch_2.lzfse": try Self.encode(["a": "v2", "c": "v2"]),
        "patch_3.lzfse": try Self.encode(["a": "v3"]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": "v3", "b": "v1", "c": "v2"])
    #expect(try harness.localManifest()?.latestPatch == 3)
    #expect(await harness.server.requested == ["manifest.json", "patch_2.lzfse", "patch_3.lzfse"])
  }

  @Test func whenAPatchIsMissing_shouldNotAdvanceThePatchLevel() async throws {
    let harness = try makeHarness(
      localDatabase: ["a": "v1"],
      localManifest: try Self.manifest("m1", chunks: 2, patch: 1),
      serverFiles: [
        "manifest.json": try Self.manifest("m1", chunks: 2, patch: 3),
        "patch_2.lzfse": try Self.encode(["a": "v2"]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": "v1"])
    #expect(try harness.localManifest()?.latestPatch == 1)
  }

  @Test func whenTheServerRebased_shouldDownloadTheNewMaster() async throws {
    let harness = try makeHarness(
      localDatabase: ["a": "old", "gone": "old"],
      localManifest: try Self.manifest("m1", chunks: 1, patch: 5),
      serverFiles: [
        "manifest.json": try Self.manifest("m2", chunks: 1, patch: 0),
        "MTG_Hashes_Master_0.lzfse": try Self.encode(["a": "new"]),
      ]
    )

    await harness.manager.sync()

    #expect(try harness.localDatabase() == ["a": "new"])
    #expect(try harness.localManifest()?.masterVersion == "m2")
  }

  @Test func whenAlreadyCurrent_shouldOnlyFetchTheManifest() async throws {
    let manifest = try Self.manifest("m1", chunks: 2, patch: 4)
    let harness = try makeHarness(
      localDatabase: ["a": "v4"],
      localManifest: manifest,
      serverFiles: ["manifest.json": manifest]
    )

    await harness.manager.sync()

    #expect(await harness.server.requested == ["manifest.json"])
    #expect(try harness.localDatabase() == ["a": "v4"])
  }
}
