@testable import Networking
import Dependencies
import Foundation
import ScryfallKit
import SQLiteData
import Testing

struct CachedMagicCardQueryRequestClientTests {
  private struct Harness {
    let client: CachedMagicCardQueryRequestClient
    let remote: SpyCardQueryRequestClient
    let store: CardStore
    let clock: TestClock
  }

  private func makeHarness(pages: [Int: [Card]], totalCards: Int) throws -> Harness {
    let database = try makeTestDatabase()
    let remote = SpyCardQueryRequestClient(pages: pages, totalCards: totalCards)
    let clock = TestClock()

    let (client, store) = withDependencies {
      $0.context = .test
      $0.defaultDatabase = database
      $0.date = .init { clock.now }
      $0.remoteCardQueryRequestClient = remote
    } operation: {
      (CachedMagicCardQueryRequestClient(), CardStore())
    }

    return Harness(client: client, remote: remote, store: store, clock: clock)
  }

  private func markCatalogComplete(_ store: CardStore, cards: Int) async throws {
    try await store.upsert(
      syncState: SyncStateRecord(
        id: BulkDataItem.defaultCardsType,
        ingestedCardCount: cards,
        status: SyncStateRecord.Status.complete.rawValue
      )
    )
  }

  @Test func whenNothingIsCached_shouldFetchAndPersistBothCardsAndOrdering() async throws {
    let cards = CardFixtures.set(code: "fdn", count: 4)
    let harness = try makeHarness(pages: [1: cards], totalCards: 4)

    let result = try await harness.client.queryCards(QueryFixtures.setBrowse())

    #expect(harness.remote.callCount == 1)
    #expect(result.data.map(\.id) == cards.map(\.id))
    #expect(try await harness.store.cardCount(inSet: "fdn") == 4)

    let page = try #require(
      try await harness.store.page(queryKey: QueryFixtures.setBrowse().cacheKey, page: 1)
    )
    #expect(try page.orderedCardIDs() == cards.map(\.id))
  }

  @Test func whenAPageIsCached_shouldNotHitTheNetworkAgain() async throws {
    let cards = CardFixtures.set(code: "fdn", count: 4)
    let harness = try makeHarness(pages: [1: cards], totalCards: 4)
    _ = try await harness.client.queryCards(QueryFixtures.setBrowse())

    let result = try await harness.client.queryCards(QueryFixtures.setBrowse())

    #expect(harness.remote.callCount == 1)
    #expect(result.data.map(\.id) == cards.map(\.id))
  }

  @Test func whenReplayingAPage_shouldPreserveScryfallsOrdering() async throws {
    let cards = [
      CardFixtures.card(name: "Zebra", collectorNumber: "9"),
      CardFixtures.card(name: "Ajani", collectorNumber: "3"),
      CardFixtures.card(name: "Mox", collectorNumber: "1"),
    ]
    let harness = try makeHarness(pages: [1: cards], totalCards: 3)
    _ = try await harness.client.queryCards(QueryFixtures.setBrowse())

    let result = try await harness.client.queryCards(QueryFixtures.setBrowse())

    #expect(result.data.map(\.name) == ["Zebra", "Ajani", "Mox"])
  }

  @Test func whenACachedPageIsADayOld_shouldRefetch() async throws {
    let cards = CardFixtures.set(code: "fdn", count: 2)
    let harness = try makeHarness(pages: [1: cards], totalCards: 2)
    _ = try await harness.client.queryCards(QueryFixtures.setBrowse())

    harness.clock.advancePastDailyBoundary()
    _ = try await harness.client.queryCards(QueryFixtures.setBrowse())

    #expect(harness.remote.callCount == 2)
  }

  @Test func whenPagingForward_shouldCacheEachPageSeparately() async throws {
    let first = CardFixtures.set(code: "fdn", count: 3)
    let second = CardFixtures.set(code: "fdn", count: 3)
    let harness = try makeHarness(pages: [1: first, 2: second], totalCards: 6)

    var query = QueryFixtures.setBrowse()
    _ = try await harness.client.queryCards(query)
    query.page = 2
    let page2 = try await harness.client.queryCards(query)
    let page2Again = try await harness.client.queryCards(query)

    #expect(harness.remote.requestedPages == [1, 2])
    #expect(page2.data.map(\.id) == second.map(\.id))
    #expect(page2Again.data.map(\.id) == second.map(\.id))
  }

  @Test func whenRevalidating_shouldHitTheNetworkEvenOnAFreshPage() async throws {
    let cards = CardFixtures.set(code: "fdn", count: 2)
    let harness = try makeHarness(pages: [1: cards], totalCards: 2)
    _ = try await harness.client.queryCards(QueryFixtures.setBrowse())

    _ = try await harness.client.queryCards(QueryFixtures.setBrowse(), policy: .revalidate)

    #expect(harness.remote.callCount == 2)
  }

  @Test func whenRevalidatingPageOne_shouldDropLaterPagesOfTheSameQuery() async throws {
    let harness = try makeHarness(
      pages: [
        1: CardFixtures.set(code: "fdn", count: 2),
        2: CardFixtures.set(code: "fdn", count: 2),
      ],
      totalCards: 4
    )

    var query = QueryFixtures.setBrowse()
    _ = try await harness.client.queryCards(query)
    query.page = 2
    _ = try await harness.client.queryCards(query)

    _ = try await harness.client.queryCards(QueryFixtures.setBrowse(), policy: .revalidate)

    #expect(try await harness.store.page(queryKey: query.cacheKey, page: 2) == nil)
    #expect(try await harness.store.page(queryKey: query.cacheKey, page: 1) != nil)
  }

  @Test func whenRevalidatingBringsUpdatedCards_shouldOverwriteTheStoredRow() async throws {
    let id = UUID()
    let harness = try makeHarness(
      pages: [1: [CardFixtures.card(id: id, name: "Old Name")]], totalCards: 1
    )
    _ = try await harness.client.queryCards(QueryFixtures.setBrowse())

    harness.remote.setPages([1: [CardFixtures.card(id: id, name: "New Name")]], totalCards: 1)
    let result = try await harness.client.queryCards(
      QueryFixtures.setBrowse(), policy: .revalidate
    )

    #expect(result.data.first?.name == "New Name")
    #expect(try await harness.store.card(id: id)?.name == "New Name")
  }

  @Test func whenOfflineWithAStalePage_shouldServeItRatherThanFail() async throws {
    let cards = CardFixtures.set(code: "fdn", count: 3)
    let harness = try makeHarness(pages: [1: cards], totalCards: 3)
    _ = try await harness.client.queryCards(QueryFixtures.setBrowse())

    harness.clock.advancePastDailyBoundary()
    harness.remote.setError(StubError())

    let result = try await harness.client.queryCards(QueryFixtures.setBrowse())

    #expect(result.data.map(\.id) == cards.map(\.id))
  }

  @Test func whenOfflineWithNothingCached_shouldThrow() async throws {
    let harness = try makeHarness(pages: [:], totalCards: 0)
    harness.remote.setError(StubError())

    await #expect(throws: StubError.self) {
      _ = try await harness.client.queryCards(QueryFixtures.setBrowse())
    }
  }

  @Test func whenTheCatalogIsComplete_shouldBrowseASetWithoutAnyRequest() async throws {
    let harness = try makeHarness(pages: [:], totalCards: 0)
    let cards = CardFixtures.set(code: "fdn", count: 5, names: ["E", "D", "C", "B", "A"])
    try await harness.store.upsert(cards: cards, source: .bulk)
    try await markCatalogComplete(harness.store, cards: cards.count)

    let result = try await harness.client.queryCards(QueryFixtures.setBrowse())

    #expect(harness.remote.callCount == 0)
    #expect(result.data.map(\.name) == ["A", "B", "C", "D", "E"])
    #expect(result.totalCards == 5)
    #expect(result.hasMore == false)
  }

  @Test func whenTheCatalogIsCompleteAndTheSetIsLarge_shouldReportMorePages() async throws {
    let harness = try makeHarness(pages: [:], totalCards: 0)
    let count = CardStore.pageSize + 20
    try await harness.store.upsert(
      cards: CardFixtures.set(code: "fdn", count: count), source: .bulk)
    try await markCatalogComplete(harness.store, cards: count)

    let result = try await harness.client.queryCards(QueryFixtures.setBrowse())

    #expect(result.data.count == CardStore.pageSize)
    #expect(result.hasMore == true)
    #expect(result.totalCards == count)
    #expect(harness.remote.callCount == 0)
  }

  @Test func whenTheCatalogIsCompleteButTheQueryIsFiltered_shouldStillAskScryfall() async throws {
    let harness = try makeHarness(
      pages: [1: CardFixtures.set(code: "fdn", count: 1)], totalCards: 1
    )
    try await harness.store.upsert(
      cards: CardFixtures.set(code: "fdn", count: 5), source: .bulk)
    try await markCatalogComplete(harness.store, cards: 5)

    var query = QueryFixtures.setBrowse()
    query.name = "bolt"

    _ = try await harness.client.queryCards(query)

    #expect(harness.remote.callCount == 1)
  }

  @Test func whenTheCatalogIsCompleteButTheSetIsUnknown_shouldFallBackToTheNetwork() async throws {
    let harness = try makeHarness(
      pages: [1: CardFixtures.set(code: "zzz", count: 2)], totalCards: 2
    )
    try await harness.store.upsert(
      cards: CardFixtures.set(code: "fdn", count: 3), source: .bulk)
    try await markCatalogComplete(harness.store, cards: 3)

    let result = try await harness.client.queryCards(QueryFixtures.setBrowse(setCode: "zzz"))

    #expect(harness.remote.callCount == 1)
    #expect(result.data.count == 2)
  }

  @Test func whenTheCatalogIsIncomplete_shouldNotServeFromIt() async throws {
    let harness = try makeHarness(
      pages: [1: CardFixtures.set(code: "fdn", count: 2)], totalCards: 2
    )
    try await harness.store.upsert(
      cards: CardFixtures.set(code: "fdn", count: 3), source: .bulk)

    _ = try await harness.client.queryCards(QueryFixtures.setBrowse())

    #expect(harness.remote.callCount == 1)
  }

  @Test func whenACardIsCached_shouldNotHitTheNetwork() async throws {
    let harness = try makeHarness(pages: [:], totalCards: 0)
    let card = CardFixtures.card(name: "Black Lotus")
    try await harness.store.upsert(cards: [card], source: .bulk)

    let loaded = try await harness.client.queryCard(for: card.id.uuidString)

    #expect(harness.remote.callCount == 0)
    #expect(loaded == card)
  }

  @Test func whenACardIsNotCached_shouldFetchAndStoreIt() async throws {
    let harness = try makeHarness(pages: [:], totalCards: 0)
    let card = CardFixtures.card(name: "Mox Ruby")
    harness.remote.setCard(card)

    let loaded = try await harness.client.queryCard(for: card.id.uuidString)

    #expect(harness.remote.callCount == 1)
    #expect(loaded == card)
    #expect(try await harness.store.card(id: card.id) == card)
  }

  @Test func whenAskingForARandomErrorCard_shouldAlwaysGoLive() async throws {
    let harness = try makeHarness(pages: [:], totalCards: 0)

    _ = try await harness.client.randomlyQueryErrorCard()
    _ = try await harness.client.randomlyQueryErrorCard()

    #expect(harness.remote.callCount == 2)
  }
}
