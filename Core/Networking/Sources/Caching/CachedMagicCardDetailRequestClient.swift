import ComposableArchitecture
import Foundation
import ScryfallKit

public struct CachedMagicCardDetailRequestClient: MagicCardDetailRequestClient {
  @Dependency(\.remoteCardDetailRequestClient) private var remote
  @Dependency(\.date.now) private var now

  private let store = CardStore()

  public init() {}

  public func getRulings(of card: Card) async throws -> [MagicCardRuling] {
    try await remote.getRulings(of: card)
  }

  public func getSet(of card: Card) async throws -> MTGSet {
    if let cached = try? await store.set(code: card.set) {
      return cached
    }

    let set = try await remote.getSet(of: card)
    _ = try? await store.upsert(sets: [set])
    return set
  }

  public func getVariants(of card: Card, page: Int) async throws -> ObjectList<Card> {
    guard let oracleID = card.oracleId else {
      throw MagicCardDetailRequestClientError.cardOracleIDIsNil
    }

    if let local = try await localVariants(oracleID: oracleID, page: page) {
      return local
    }

    let key = Self.variantsCacheKey(oracleID: oracleID)

    if let record = try? await store.page(queryKey: key, page: page), record.isStale(since: now) == false {
      let ids = try record.orderedCardIDs()
      let cards = try await store.cards(ids: ids)

      if cards.count == ids.count, ids.isEmpty == false {
        return ObjectList(
          data: cards, hasMore: record.hasMore, nextPage: nil, totalCards: record.totalCards
        )
      }
    }

    let result = try await remote.getVariants(of: card, page: page)
    _ = try? await store.upsert(
      cards: result.data,
      source: .api
    )
    
    _ = try? await store.upsert(
      page: CardPageRecord(
        queryKey: key,
        page: page,
        cardIDs: result.data.map(\.id),
        hasMore: result.hasMore ?? false,
        totalCards: result.totalCards ?? result.data.count,
        fetchedAt: now
      )
    )

    return result
  }

  public func getRelatedCardsIfNeeded(
    of card: Card,
    for type: Card.RelatedCard.Component
  ) async throws -> CardDataSource? {
    guard
      let parts = card.allParts?.filter({ $0.component == type }),
      parts.isEmpty == false
    else {
      return nil
    }

    let ids = parts.map(\.id)
    
    if let cached = try? await store.cards(ids: ids), cached.count == ids.count {
      return Self.dataSource(from: cached, excluding: card)
    }

    let result = try await remote.getRelatedCardsIfNeeded(of: card, for: type)

    if let result {
      _ = try? await store.upsert(
        cards: result.cardDetails.map(\.card), source: .api
      )
    }

    return result
  }

  static func variantsCacheKey(oracleID: String) -> String {
    "variants|o=\(oracleID)"
  }

  private func localVariants(oracleID: String, page: Int) async throws -> ObjectList<Card>? {
    guard
      let state = try? await store.syncState(id: BulkDataItem.defaultCardsType),
      state.hasCompleteCatalog
    else {
      return nil
    }

    let result = try await store.cards(withOracleID: oracleID, page: page)
    guard result.total > 0 else { return nil }

    return ObjectList(
      data: result.cards,
      hasMore: page * CardStore.pageSize < result.total,
      nextPage: nil,
      totalCards: result.total
    )
  }
  
  private static func dataSource(from cards: [Card], excluding card: Card) -> CardDataSource? {
    let related = cards.filter {
      $0.oracleId != card.oracleId && $0.games.contains(.arena) == false
    }

    guard related.isEmpty == false else { return nil }
    return CardDataSource(cards: related, hasNextPage: false, total: related.count)
  }
}

public enum RemoteMagicCardDetailRequestClientKey: DependencyKey {
  public static let liveValue: any MagicCardDetailRequestClient = ScryfallClient()
#if DEBUG
  public static let previewValue: any MagicCardDetailRequestClient = MockCardDetailRequestClient()
  public static let testValue: any MagicCardDetailRequestClient = MockCardDetailRequestClient()
#endif
}

public extension DependencyValues {
  var remoteCardDetailRequestClient: any MagicCardDetailRequestClient {
    get { self[RemoteMagicCardDetailRequestClientKey.self] }
    set { self[RemoteMagicCardDetailRequestClientKey.self] = newValue }
  }
}
