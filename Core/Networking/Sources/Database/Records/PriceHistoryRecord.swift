import Foundation
import SQLiteData

/// One card's price history from one provider's list, kept until MTGJSON makes a new build.
///
/// The feed behind MTGGraphQL is rebuilt from MTGJSON's daily build, so a stored history is exactly
/// as current as the build it was read from: asking again before the next build returns the same
/// points and spends one of the token's 500 hourly requests for nothing.
@Table("priceHistories")
public struct PriceHistoryRecord: Equatable, Sendable {
  /// `"<card id>/<provider>/<list type>"`.
  public var id: String
  public var cardID: String
  public var currency: String
  /// JSON-encoded `[PriceSeriesKind raw value: [PricePoint]]`.
  public var payload: Data
  /// The MTGJSON build the history was read from, when it could be asked for.
  public var mtgjsonVersion: String?
  public var fetchedAt: Int64

  public init(
    id: String,
    cardID: String,
    currency: String,
    payload: Data,
    mtgjsonVersion: String?,
    fetchedAt: Int64
  ) {
    self.id = id
    self.cardID = cardID
    self.currency = currency
    self.payload = payload
    self.mtgjsonVersion = mtgjsonVersion
    self.fetchedAt = fetchedAt
  }
}

public extension PriceHistoryRecord {
  static func identifier(cardID: String, request: PriceSeriesRequest) -> String {
    "\(cardID.lowercased())/\(request.provider.rawValue)/\(request.listType.rawValue)"
  }

  init(history: PriceHistory, mtgjsonVersion: String?, fetchedAt: Date) throws {
    let series = Dictionary(uniqueKeysWithValues: history.series.map { ($0.key.rawValue, $0.value) })
    self.init(
      id: Self.identifier(
        cardID: history.cardID,
        request: PriceSeriesRequest(provider: history.provider, listType: history.listType)
      ),
      cardID: history.cardID,
      currency: history.currency,
      payload: try JSONEncoder().encode(series),
      mtgjsonVersion: mtgjsonVersion,
      fetchedAt: Int64(fetchedAt.timeIntervalSince1970)
    )
  }

  func history(for request: PriceSeriesRequest) throws -> PriceHistory {
    let series = try JSONDecoder().decode([String: [PricePoint]].self, from: payload)
    return PriceHistory(
      cardID: cardID,
      provider: request.provider,
      listType: request.listType,
      currency: currency,
      series: Dictionary(uniqueKeysWithValues: series.compactMap { key, points in
        PriceSeriesKind(rawValue: key).map { ($0, points) }
      })
    )
  }

  /// Current while MTGJSON is still on the build it was read from. When the build cannot be asked
  /// for, a day's age stands in for it: MTGJSON builds at most once a day.
  func isCurrent(build: String?, now: Date) -> Bool {
    if let build {
      return mtgjsonVersion == build
    }
    return now.timeIntervalSince(Date(timeIntervalSince1970: Double(fetchedAt))) < 24 * 60 * 60
  }
}
