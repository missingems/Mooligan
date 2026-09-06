import Foundation
import SQLiteData

@Table("cardPages")
public struct CardPageRecord: Equatable, Sendable {
  public var id: String
  public var queryKey: String
  public var page: Int
  public var cardIDs: Data
  public var hasMore: Bool
  public var totalCards: Int
  public var fetchedAt: Int64

  public init(
    id: String,
    queryKey: String,
    page: Int,
    cardIDs: Data,
    hasMore: Bool,
    totalCards: Int,
    fetchedAt: Int64
  ) {
    self.id = id
    self.queryKey = queryKey
    self.page = page
    self.cardIDs = cardIDs
    self.hasMore = hasMore
    self.totalCards = totalCards
    self.fetchedAt = fetchedAt
  }
}

public extension CardPageRecord {
  static func identifier(queryKey: String, page: Int) -> String {
    "\(queryKey)#\(page)"
  }

  init(
    queryKey: String,
    page: Int,
    cardIDs: [UUID],
    hasMore: Bool,
    totalCards: Int,
    fetchedAt: Date
  ) throws {
    self.init(
      id: Self.identifier(queryKey: queryKey, page: page),
      queryKey: queryKey,
      page: page,
      cardIDs: try JSONEncoder().encode(cardIDs.map(\.uuidString)),
      hasMore: hasMore,
      totalCards: totalCards,
      fetchedAt: Int64(fetchedAt.timeIntervalSince1970)
    )
  }

  func orderedCardIDs() throws -> [UUID] {
    try JSONDecoder().decode([String].self, from: cardIDs).compactMap(UUID.init(uuidString:))
  }

  func isStale(since now: Date) -> Bool {
    BulkRefreshSchedule.isCheckDue(
      lastCheckedAt: Date(timeIntervalSince1970: Double(fetchedAt)),
      now: now
    )
  }
}
