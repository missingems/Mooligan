@testable import Networking
import Foundation
import ScryfallKit

final class StubBulkDataRequestClient: BulkDataRequestClient, @unchecked Sendable {
  private let lock = NSLock()
  private var _items: [BulkDataItem]
  private var _callCount = 0
  private var _error: (any Error)?

  init(items: [BulkDataItem]) {
    _items = items
  }

  var callCount: Int {
    lock.withLock { _callCount }
  }

  func setItems(_ items: [BulkDataItem]) {
    lock.withLock { _items = items }
  }

  func setError(_ error: (any Error)?) {
    lock.withLock { _error = error }
  }

  func bulkDataItems() async throws -> [BulkDataItem] {
    try lock.withLock {
      _callCount += 1
      if let _error { throw _error }
      return _items
    }
  }
}

actor StubBulkDataDownloader: BulkDataDownloading {
  private var staged: [URL: URL] = [:]
  private(set) var enqueuedURLs: [URL] = []
  private(set) var discardedURLs: [URL] = []

  init() {}

  func stage(_ contents: Data, for url: URL) throws {
    let file = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("bulk-\(UUID().uuidString).gz")
    try contents.write(to: file)
    staged[url] = file
  }

  func stagedFile(for url: URL) -> URL? {
    staged[url]
  }

  func enqueueDownload(from url: URL) {
    enqueuedURLs.append(url)
  }

  func discardStagedFile(for url: URL) {
    discardedURLs.append(url)

    if let file = staged.removeValue(forKey: url) {
      try? FileManager.default.removeItem(at: file)
    }
  }

  func download(from url: URL) async throws -> URL {
    guard let file = staged[url] else { throw BulkDataDownloadError.cancelled }
    return file
  }
}

enum BulkFixture {
  static func item(
    updatedAt: String,
    downloadURI: String = "https://data.scryfall.io/default-cards/default-cards-1.jsonl.gz"
  ) -> BulkDataItem {
    BulkDataItem(
      id: "e2ef41e3-5778-4bc2-af3f-78eca4dd9c23",
      type: BulkDataItem.defaultCardsType,
      name: "Default Cards",
      description: "Every card object on Scryfall.",
      uri: "https://api.scryfall.com/bulk-data/e2ef41e3-5778-4bc2-af3f-78eca4dd9c23",
      updatedAt: updatedAt,
      jsonlDownloadURI: downloadURI,
      compressedSize: 78_058_074
    )
  }

  static func gzippedJSONL(cards: [Card], extraLines: [String] = []) throws -> Data {
    var body = Data()

    for card in cards {
      let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(card))
      let snakeCased = snakeCaseKeys(object)
      body.append(try JSONSerialization.data(withJSONObject: snakeCased, options: [.sortedKeys]))
      body.append(0x0A)
    }

    for line in extraLines {
      body.append(Data(line.utf8))
      body.append(0x0A)
    }

    return try GzipFixture.compress(body)
  }

  private static func snakeCaseKeys(_ value: Any) -> Any {
    switch value {
    case let dictionary as [String: Any]:
      Dictionary(
        uniqueKeysWithValues: dictionary.map { (snakeCased($0.key), snakeCaseKeys($0.value)) }
      )
    case let array as [Any]:
      array.map(snakeCaseKeys)
    default:
      value
    }
  }

  private static func snakeCased(_ key: String) -> String {
    var output = ""
    for character in key {
      if character.isUppercase {
        output.append("_")
        output.append(Character(character.lowercased()))
      } else {
        output.append(character)
      }
    }
    return output
  }
}
