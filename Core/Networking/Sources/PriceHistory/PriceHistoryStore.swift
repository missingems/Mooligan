import Dependencies
import Foundation
import SQLiteData

/// Where price histories are kept between launches.
struct PriceHistoryStore: Sendable {
  @Dependency(\.defaultDatabase) private var database
  @Dependency(\.date.now) private var now

  func records(
    cardID: String,
    requests: [PriceSeriesRequest]
  ) async throws -> [PriceSeriesRequest: PriceHistoryRecord] {
    let ids = requests.map { PriceHistoryRecord.identifier(cardID: cardID, request: $0) }
    let records = try await database.read { connection in
      try PriceHistoryRecord.where { $0.id.in(ids) }.fetchAll(connection)
    }
    let byID = Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    return Dictionary(uniqueKeysWithValues: requests.compactMap { request in
      byID[PriceHistoryRecord.identifier(cardID: cardID, request: request)].map { (request, $0) }
    })
  }

  func save(_ histories: some Collection<PriceHistory>, mtgjsonVersion: String?) async throws {
    let records = try histories.map {
      try PriceHistoryRecord(history: $0, mtgjsonVersion: mtgjsonVersion, fetchedAt: now)
    }
    guard records.isEmpty == false else { return }

    try await database.write { connection in
      for record in records {
        try PriceHistoryRecord.upsert { record }.execute(connection)
      }
    }
  }
}
