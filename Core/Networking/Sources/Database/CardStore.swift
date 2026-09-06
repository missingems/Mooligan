import Dependencies
import Foundation
import ScryfallKit
import SQLiteData

public struct CardStore: Sendable {
  public static let pageSize = 175

  @Dependency(\.defaultDatabase) private var database
  @Dependency(\.date.now) private var now

  public init() {}

  @discardableResult
  public func upsert(cards: [Card], source: CardRecord.Source) async throws -> Int {
    guard cards.isEmpty == false else { return 0 }

    let records = cards.map { CardRecord(card: $0, source: source, ingestedAt: now) }

    try await database.write { connection in
      for record in records {
        try CardRecord.upsert { record }.execute(connection)
      }
    }

    return records.count
  }

  public func cards(ids: [UUID]) async throws -> [Card] {
    guard ids.isEmpty == false else { return [] }

    let records = try await database.read { connection in
      try CardRecord
        .where { $0.id.in(ids.map(UUID.BytesRepresentation.init(queryOutput:))) }
        .fetchAll(connection)
    }

    let byID = Dictionary(
      records.map { ($0.id, $0) },
      uniquingKeysWith: { (first: CardRecord, _: CardRecord) in first }
    )

    return ids.compactMap { byID[$0]?.card }
  }

  public func card(id: UUID) async throws -> Card? {
    let record = try await database.read { connection in
      try CardRecord.where { $0.id.eq(UUID.BytesRepresentation(queryOutput: id)) }.fetchOne(connection)
    }

    return record?.card
  }

  @discardableResult public func deleteBulkCards(ingestedBefore cutoff: Date) async throws -> Int {
    let stamp = Int64(cutoff.timeIntervalSince1970)

    return try await database.write { connection in
      let doomed = try CardRecord
        .where { $0.source.eq(CardRecord.Source.bulk.rawValue) && $0.ingestedAt.lt(stamp) }
        .fetchCount(connection)

      try CardRecord
        .where { $0.source.eq(CardRecord.Source.bulk.rawValue) && $0.ingestedAt.lt(stamp) }
        .delete()
        .execute(connection)

      return doomed
    }
  }

  public func cardCount(inSet setCode: String) async throws -> Int {
    try await database.read { connection in
      try CardRecord.where { $0.setCode.eq(setCode) && $0.isPaper }.fetchCount(connection)
    }
  }

  public func cards(
    inSet setCode: String,
    sortMode: SortMode,
    sortDirection: SortDirection,
    page: Int
  ) async throws -> (cards: [Card], total: Int) {
    let offset = max(0, page - 1) * Self.pageSize
    let ordering = Self.orderingClause(sortMode: sortMode, sortDirection: sortDirection)

    let (records, total) = try await database.read { connection in
      let records = try #sql(
        """
        SELECT \(CardRecord.columns) FROM "cards"
        WHERE "setCode" = \(bind: setCode) AND "isPaper" = 1
        ORDER BY \(ordering)
        LIMIT \(bind: Self.pageSize) OFFSET \(bind: offset)
        """,
        as: CardRecord.self
      )
      .fetchAll(connection)

      let total = try CardRecord.where { $0.setCode.eq(setCode) && $0.isPaper }.fetchCount(connection)
      return (records, total)
    }

    return (records.map(\.card), total)
  }
  
  static func orderingClause(sortMode: SortMode, sortDirection: SortDirection) -> QueryFragment {
    let descending = sortDirection == .desc
    let direction: QueryFragment = descending ? "DESC" : "ASC"

    let primary: QueryFragment = switch sortMode {
    case .name: "\(quote: "name") \(direction)"
    case .released: "\(quote: "releasedAt") \(direction)"
    case .rarity: "\(quote: "rarityRank") \(direction)"
    case .color: "\(quote: "colorRank") \(direction)"
    case .cmc: "\(quote: "cmc") \(direction)"
    case .usd: "\(quote: "usd") \(direction) NULLS LAST"
    default: "\(quote: "collectorNumberSort") \(direction)"
    }

    return "\(primary), \(quote: "collectorNumberSort") ASC"
  }
  
  public func cards(withOracleID oracleID: String, page: Int) async throws -> (
    cards: [Card], total: Int
  ) {
    let offset = max(0, page - 1) * Self.pageSize

    let (records, total) = try await database.read { connection in
      let records = try CardRecord
        .where { $0.oracleID.eq(oracleID) && $0.isPaper }
        .order { ($0.releasedAt.desc(), $0.collectorNumberSort.asc()) }
        .limit { _ in Self.pageSize }
        .offset { _ in offset }
        .fetchAll(connection)

      let total = try CardRecord
        .where { $0.oracleID.eq(oracleID) && $0.isPaper }
        .fetchCount(connection)

      return (records, total)
    }

    return (records.map(\.card), total)
  }

  @discardableResult
  public func upsert(sets: [MTGSet]) async throws -> Int {
    guard sets.isEmpty == false else { return 0 }

    let records = try sets.map { try GameSetRecord(set: $0, fetchedAt: now) }

    try await database.write { connection in
      for record in records {
        try GameSetRecord.upsert { record }.execute(connection)
      }
    }

    return records.count
  }

  public func set(code: String) async throws -> MTGSet? {
    try await database.read { connection in
      try GameSetRecord.where {
        $0.code.eq(code)
      }.fetchOne(connection)
    }?.gameSet()
  }

  public func allSets() async throws -> [MTGSet] {
    try await database.read { connection in
      try GameSetRecord.all
        .order {
          ($0.releasedAt.desc(), $0.code.asc())
        }
        .fetchAll(connection)
    }.map {
      try $0.gameSet()
    }
  }

  public func setsFetchedAt() async throws -> Date? {
    let value = try await database.read { connection in
      try GameSetRecord.select { $0.fetchedAt.max() }.fetchOne(connection)
    }

    return value.flatMap { $0 }.map { Date(timeIntervalSince1970: Double($0)) }
  }

  public func page(queryKey: String, page: Int) async throws -> CardPageRecord? {
    let id = CardPageRecord.identifier(queryKey: queryKey, page: page)

    return try await database.read { connection in
      try CardPageRecord.where { $0.id.eq(id) }.fetchOne(connection)
    }
  }

  public func upsert(page record: CardPageRecord) async throws {
    try await database.write { connection in
      try CardPageRecord.upsert { record }.execute(connection)
    }
  }

  public func invalidatePages(queryKey: String) async throws {
    try await database.write { connection in
      try CardPageRecord.where { $0.queryKey.eq(queryKey) }.delete().execute(connection)
    }
  }

  public func syncState(id: String) async throws -> SyncStateRecord? {
    try await database.read { connection in
      try SyncStateRecord.where { $0.id.eq(id) }.fetchOne(connection)
    }
  }

  public func upsert(syncState record: SyncStateRecord) async throws {
    try await database.write { connection in
      try SyncStateRecord.upsert { record }.execute(connection)
    }
  }
}
