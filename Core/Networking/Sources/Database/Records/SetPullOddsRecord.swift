import Foundation
import SQLiteData

/// One set's pull odds, worked out from its MTGJSON file and kept so the file is
/// downloaded once rather than every time one of its cards is opened.
@Table("setPullOdds")
public struct SetPullOddsRecord: Equatable, Sendable {
  /// The set code, lowercased.
  public var id: String

  /// JSON-encoded `SetPullOdds`.
  public var payload: Data

  public var fetchedAt: Int64

  public init(id: String, payload: Data, fetchedAt: Int64) {
    self.id = id
    self.payload = payload
    self.fetchedAt = fetchedAt
  }
}

extension SetPullOddsRecord {
  init(setCode: String, odds: SetPullOdds, fetchedAt: Date) throws {
    self.init(
      id: setCode.lowercased(),
      payload: try JSONEncoder().encode(odds),
      fetchedAt: Int64(fetchedAt.timeIntervalSince1970)
    )
  }

  var odds: SetPullOdds? {
    try? JSONDecoder().decode(SetPullOdds.self, from: payload)
  }
}
