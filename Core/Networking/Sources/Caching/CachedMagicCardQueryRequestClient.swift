import ComposableArchitecture
import Foundation
import ScryfallKit

public struct CachedMagicCardQueryRequestClient: MagicCardQueryRequestClient {
  @Dependency(\.remoteCardQueryRequestClient) private var remote
  @Dependency(\.date.now) private var now

  private let store = CardStore()

  public init() {}

  public func queryCards(_ query: SearchQuery) async throws -> ObjectList<Card> {
    try await queryCards(query, policy: .cacheFirst)
  }

  public func queryCards(
    _ query: SearchQuery,
    policy: CachePolicy
  ) async throws -> ObjectList<Card> {
    if policy == .cacheFirst {
      if let local = try await localSetBrowse(query) {
        return local
      }

      if let cached = try await cachedPage(query, allowStale: false) {
        return cached
      }
    }

    do {
      return try await fetchAndStore(query, invalidatingQuery: policy == .revalidate)
    } catch {
      if let cached = try await cachedPage(query, allowStale: true) {
        return cached
      }
      if let local = try await localSetBrowse(query) {
        return local
      }
      throw error
    }
  }

  public func queryCard(for id: String) async throws -> Card {
    if let uuid = UUID(uuidString: id), let cached = try? await store.card(id: uuid) {
      return cached
    }

    let card = try await remote.queryCard(for: id)
    _ = try? await store.upsert(cards: [card], source: .api)
    return card
  }

  public func randomlyQueryErrorCard() async throws -> Card {
    try await remote.randomlyQueryErrorCard()
  }

  private func localSetBrowse(_ query: SearchQuery) async throws -> ObjectList<Card>? {
    guard
      query.isUnfilteredSetBrowse,
      let setCode = query.setCode,
      let state = try? await store.syncState(id: BulkDataItem.defaultCardsType),
      state.hasCompleteCatalog
    else {
      return nil
    }

    let result = try await store.cards(
      inSet: setCode,
      sortMode: query.sortMode,
      sortDirection: query.sortDirection,
      page: query.page
    )

    guard result.total > 0 else { return nil }

    return ObjectList(
      data: result.cards,
      hasMore: query.page * CardStore.pageSize < result.total,
      nextPage: nil,
      totalCards: result.total
    )
  }

  private func cachedPage(
    _ query: SearchQuery,
    allowStale: Bool
  ) async throws -> ObjectList<Card>? {
    guard let record = try? await store.page(queryKey: query.cacheKey, page: query.page) else {
      return nil
    }

    if allowStale == false, record.isStale(since: now) {
      return nil
    }

    let ids = try record.orderedCardIDs()
    let cards = try await store.cards(ids: ids)

    guard cards.count == ids.count, ids.isEmpty == false else { return nil }

    return ObjectList(
      data: cards,
      hasMore: record.hasMore,
      nextPage: nil,
      totalCards: record.totalCards
    )
  }

  private func fetchAndStore(
    _ query: SearchQuery,
    invalidatingQuery: Bool
  ) async throws -> ObjectList<Card> {
    let result = try await remote.queryCards(query)

    if invalidatingQuery, query.page == 1 {
      _ = try? await store.invalidatePages(queryKey: query.cacheKey)
    }

    _ = try? await store.upsert(cards: result.data, source: .api)
    _ = try? await store.upsert(
      page: CardPageRecord(
        queryKey: query.cacheKey,
        page: query.page,
        cardIDs: result.data.map(\.id),
        hasMore: result.hasMore ?? false,
        totalCards: result.totalCards ?? result.data.count,
        fetchedAt: now
      )
    )

    return result
  }
}

public enum RemoteMagicCardQueryRequestClientKey: DependencyKey {
  public static let liveValue: any MagicCardQueryRequestClient = ScryfallClient()
#if DEBUG
  public static let previewValue: any MagicCardQueryRequestClient = MockCardQueryRequestClient()
  public static let testValue: any MagicCardQueryRequestClient = MockCardQueryRequestClient()
#endif
}

public extension DependencyValues {
  var remoteCardQueryRequestClient: any MagicCardQueryRequestClient {
    get { self[RemoteMagicCardQueryRequestClientKey.self] }
    set { self[RemoteMagicCardQueryRequestClientKey.self] = newValue }
  }
}
