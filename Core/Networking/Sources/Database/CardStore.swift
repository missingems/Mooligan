import Dependencies
import Foundation
import ScryfallKit
import SQLiteData

public struct CardStore: Sendable {
  public static let pageSize = 175
  
  @Dependency(\.defaultDatabase) var database
  @Dependency(\.date.now) private var now
  
  @discardableResult public func upsert(cards: [Card], source: CardRecord.Source) async throws -> Int {
    guard cards.isEmpty == false else {
      return 0
    }
    
    return try await Task.detached(priority: .background) { [db = self.database, currentTime = self.now] in
      let records = cards.map {
        CardRecord(card: $0, source: source, ingestedAt: currentTime)
      }
      
      try await db.write { connection in
        for record in records {
          try CardRecord.upsert {
            record
          }
          .execute(connection)
        }
      }
      
      return records.count
    }
    .value
  }
  
  public func cards(ids: [UUID]) async throws -> [Card] {
    guard ids.isEmpty == false else { return [] }
    
    return try await Task.detached(priority: .background) { [db = self.database] in
      let records = try await db.read { connection in
        try CardRecord
          .where { $0.id.in(ids.map(UUID.BytesRepresentation.init(queryOutput:))) }
          .fetchAll(connection)
      }
      
      let byID = Dictionary(
        records.map { ($0.id, $0) },
        uniquingKeysWith: { (first: CardRecord, _: CardRecord) in first }
      )
      
      return ids.compactMap {
        byID[$0]?.card
      }
    }
    .value
  }
  
  public func card(id: UUID) async throws -> Card? {
    try await Task.detached(priority: .background) { [db = self.database] in
      try await db.read { connection in
        try CardRecord.where {
          $0.id.eq(UUID.BytesRepresentation(queryOutput: id))
        }
        .fetchOne(connection)
      }?.card
    }
    .value
  }
  
  @discardableResult public func deleteBulkCards(ingestedBefore cutoff: Date) async throws -> Int {
    try await Task.detached(priority: .background) { [db = self.database, stamp = Int64(cutoff.timeIntervalSince1970)] in
      try await db.write { connection in
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
    .value
  }
  
  public func cardCount(inSet setCode: String) async throws -> Int {
    try await Task.detached(priority: .background) { [db = self.database] in
      try await db.read { connection in
        try CardRecord.where { $0.setCode.eq(setCode) && $0.isPaper }.fetchCount(connection)
      }
    }
    .value
  }
  
  public func cards(
    inSet setCode: String,
    sortMode: SortMode,
    sortDirection: SortDirection,
    page: Int
  ) async throws -> (cards: [Card], total: Int) {
    try await Task.detached(priority: .background) { [db = self.database] in
      let offset = max(0, page - 1) * Self.pageSize
      let ordering = Self.orderingClause(sortMode: sortMode, sortDirection: sortDirection)
      
      let (records, total) = try await db.read { connection in
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
    .value
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
  
  public func cards(withOracleID oracleID: String, page: Int) async throws -> (cards: [Card], total: Int) {
    try await Task.detached(priority: .background) { [db = self.database] in
      let offset = max(0, page - 1) * Self.pageSize
      
      let (records, total) = try await db.read { connection in
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
    .value
  }
  
  @discardableResult public func upsert(sets: [MTGSet]) async throws -> Int {
    guard sets.isEmpty == false else { return 0 }
    
    return try await Task.detached(priority: .background) { [db = self.database, currentTime = self.now] in
      let records = try sets.map { try GameSetRecord(set: $0, fetchedAt: currentTime) }
      
      try await db.write { connection in
        for record in records {
          try GameSetRecord.upsert { record }.execute(connection)
        }
      }
      
      return records.count
    }
    .value
  }
  
  public func set(code: String) async throws -> MTGSet? {
    try await Task.detached(priority: .background) { [db = self.database] in
      try await db.read { connection in
        try GameSetRecord.where {
          $0.code.eq(code)
        }.fetchOne(connection)
      }?.gameSet()
    }
    .value
  }
  
  public func allSets() async throws -> [MTGSet] {
    try await Task.detached(priority: .background) { [db = self.database] in
      try await db.read { connection in
        try GameSetRecord.all
          .order {
            ($0.releasedAt.desc(), $0.code.asc())
          }
          .fetchAll(connection)
      }.map {
        try $0.gameSet()
      }
    }
    .value
  }
  
  public func setsFetchedAt() async throws -> Date? {
    try await Task.detached(priority: .background) { [db = self.database] in
      try await db.read { connection in
        try GameSetRecord.select { $0.fetchedAt.max() }.fetchOne(connection)
      }
      .flatMap { $0 }.map { Date(timeIntervalSince1970: Double($0)) }
    }
    .value
  }
  
  public func page(queryKey: String, page: Int) async throws -> CardPageRecord? {
    try await Task.detached(priority: .background) { [db = self.database] in
      try await db.read { connection in
        try CardPageRecord.where {
          $0.id.eq(CardPageRecord.identifier(queryKey: queryKey, page: page))
        }
        .fetchOne(connection)
      }
    }
    .value
  }
  
  public func upsert(page record: CardPageRecord) async throws {
    try await Task.detached { [db = self.database] in
      try await db.write { connection in
        try CardPageRecord.upsert { record }.execute(connection)
      }
    }.value
  }
  
  public func invalidatePages(queryKey: String) async throws {
    try await Task.detached(priority: .background) { [db = self.database] in
      try await db.write { connection in
        try CardPageRecord.where { $0.queryKey.eq(queryKey) }.delete().execute(connection)
      }
    }
    .value
  }
  
  public func syncState(id: String) async throws -> SyncStateRecord? {
    try await Task.detached(priority: .background) { [db = self.database] in
      try await db.read { connection in
        try SyncStateRecord.where { $0.id.eq(id) }.fetchOne(connection)
      }
    }
    .value
  }
  
  public func upsert(syncState record: SyncStateRecord) async throws {
    try await Task.detached(priority: .background) { [db = self.database] in
      try await db.write { connection in
        try SyncStateRecord.upsert { record }.execute(connection)
      }
    }
    .value
  }
}
