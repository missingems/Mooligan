import ComposableArchitecture
import Foundation
import ScryfallKit

public protocol BulkDataRequestClient: Sendable {
  func bulkDataItems() async throws -> [BulkDataItem]
}

public enum BulkDataRequestClientError: Error, Equatable {
  case invalidURL
  case badStatus(Int)
  case typeNotOffered(String)
}

extension ScryfallClient: BulkDataRequestClient {
  public func bulkDataItems() async throws -> [BulkDataItem] {
    guard let url = URL(string: "https://api.scryfall.com/bulk-data") else {
      throw BulkDataRequestClientError.invalidURL
    }

    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let status = (response as? HTTPURLResponse)?.statusCode else {
      throw BulkDataRequestClientError.badStatus(-1)
    }
    guard (200..<300).contains(status) else {
      throw BulkDataRequestClientError.badStatus(status)
    }

    struct Envelope: Decodable {
      let data: [BulkDataItem]
    }

    return try JSONDecoder().decode(Envelope.self, from: data).data
  }
}

public extension Array where Element == BulkDataItem {
  func item(ofType type: String) throws -> BulkDataItem {
    guard let item = first(where: { $0.type == type }) else {
      throw BulkDataRequestClientError.typeNotOffered(type)
    }
    return item
  }
}

public enum BulkDataRequestClientKey: DependencyKey {
  public static let liveValue: any BulkDataRequestClient = ScryfallClient()
#if DEBUG
  public static let previewValue: any BulkDataRequestClient = MockBulkDataRequestClient()
  public static let testValue: any BulkDataRequestClient = MockBulkDataRequestClient()
#endif
}

public extension DependencyValues {
  var bulkDataRequestClient: any BulkDataRequestClient {
    get { self[BulkDataRequestClientKey.self] }
    set { self[BulkDataRequestClientKey.self] = newValue }
  }
}

#if DEBUG
public struct MockBulkDataRequestClient: BulkDataRequestClient {
  public init() {}

  public func bulkDataItems() async throws -> [BulkDataItem] {
    [
      BulkDataItem(
        id: "e2ef41e3-5778-4bc2-af3f-78eca4dd9c23",
        type: BulkDataItem.defaultCardsType,
        name: "Default Cards",
        description: "Every card object on Scryfall in English or the printed language.",
        uri: "https://api.scryfall.com/bulk-data/e2ef41e3-5778-4bc2-af3f-78eca4dd9c23",
        updatedAt: "2026-09-05T21:05:33.429+00:00",
        jsonlDownloadURI:
          "https://data.scryfall.io/default-cards/default-cards-20260905210533.jsonl.gz",
        compressedSize: 78_058_074
      )
    ]
  }
}
#endif
