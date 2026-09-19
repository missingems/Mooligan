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

  /// A listing comes from one place from its first page to its last: the catalog, or Scryfall. A
  /// stored first page from Scryfall means the listing is Scryfall's (it was refreshed, or the
  /// catalog could not serve it), and every later page follows it until the next daily boundary,
  /// rather than being filled in from the catalog, whose order and contents can differ.
  public func queryCards(
    _ query: SearchQuery,
    policy: CachePolicy
  ) async throws -> ObjectList<Card> {
    if policy == .cacheFirst, let cached = try await cachedListing(query) {
      return cached
    }

    do {
      return try await fetchAndStore(query)
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

  /// The page from where the listing lives, or nil when it has to be asked of Scryfall.
  private func cachedListing(_ query: SearchQuery) async throws -> ObjectList<Card>? {
    let first = try? await store.page(queryKey: query.cacheKey, page: 1)

    if query.page == 1 {
      if let first, first.isStale(since: now) == false {
        return try await cachedPage(query, allowStale: false)
      }
      guard let local = try await localSetBrowse(query) else {
        return try await cachedPage(query, allowStale: false)
      }
      // The catalog serves the listing again, so the pages Scryfall gave it before are dropped:
      // they would otherwise take over from the second page on.
      if first != nil {
        _ = try? await store.invalidatePages(queryKey: query.cacheKey)
      }
      return local
    }

    guard let first else {
      if let local = try await localSetBrowse(query) {
        return local
      }
      return try await cachedPage(query, allowStale: false)
    }

    // Scryfall's listing: a later page only if it was fetched with the first, from the same
    // snapshot of Scryfall's results.
    guard
      let record = try? await store.page(queryKey: query.cacheKey, page: query.page),
      record.fetchedAt >= first.fetchedAt
    else {
      return nil
    }
    return try await cachedPage(query, allowStale: true)
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
      state.hasCompleteCatalog,
      (try? await store.hasSortKeys(inSet: setCode)) == true
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

  private func fetchAndStore(_ query: SearchQuery) async throws -> ObjectList<Card> {
    let result = try await remote.queryCards(query)

    // A new first page starts a new listing: the later pages stored with the old one are from an
    // older snapshot of Scryfall's results, and are fetched again as they are reached.
    if query.page == 1 {
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
