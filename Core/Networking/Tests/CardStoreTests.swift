@testable import Networking
import Dependencies
import Foundation
import ScryfallKit
import SQLiteData
import Testing

struct CardStoreTests {
  private let clock = TestClock()

  private func makeStore() throws -> CardStore {
    let database = try makeTestDatabase()

    return withDependencies {
      $0.context = .test
      $0.defaultDatabase = database
      $0.date = .init { [clock] in clock.now }
    } operation: {
      CardStore()
    }
  }

  @Test func whenMigrating_shouldCreateEveryTable() throws {
    let database = try makeTestDatabase()

    let tables = try database.read { connection in
      try String.fetchAll(
        connection,
        sql: "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
      )
    }

    #expect(tables.contains("cards"))
    #expect(tables.contains("gameSets"))
    #expect(tables.contains("cardPages"))
    #expect(tables.contains("syncState"))
  }

  @Test func whenMigratingTwice_shouldBeANoOp() throws {
    let database = try makeTestDatabase()

    try migrator().migrate(database)

    let indexes = try database.read { connection in
      try String.fetchAll(
        connection,
        sql: "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'cards_%'"
      )
    }

    #expect(Set(indexes) == ["cards_set", "cards_name", "cards_oracleID"])
  }

  @Test func whenUpsertingCards_shouldRoundTripThroughThePayload() async throws {
    let store = try makeStore()
    let card = CardFixtures.card(name: "Counterspell", setCode: "mkm", collectorNumber: "7")

    try await store.upsert(cards: [card], source: .bulk)

    let loaded = try await store.card(id: card.id)
    #expect(loaded == card)
  }

  @Test func whenUpsertingTheSameCardTwice_shouldReplaceRatherThanDuplicate() async throws {
    let store = try makeStore()
    let id = UUID()
    let original = CardFixtures.card(id: id, name: "Old Name", setCode: "fdn")
    let updated = CardFixtures.card(id: id, name: "New Name", setCode: "fdn")

    try await store.upsert(cards: [original], source: .bulk)
    try await store.upsert(cards: [updated], source: .api)

    #expect(try await store.cardCount(inSet: "fdn") == 1)
    #expect(try await store.card(id: id)?.name == "New Name")
  }

  @Test func whenFetchingByIDs_shouldPreserveTheRequestedOrder() async throws {
    let store = try makeStore()
    let cards = CardFixtures.set(code: "fdn", count: 5)
    try await store.upsert(cards: cards, source: .bulk)

    let wanted = [cards[3].id, cards[0].id, cards[4].id]
    let loaded = try await store.cards(ids: wanted)

    #expect(loaded.map(\.id) == wanted)
  }

  @Test func whenFetchingByIDsWithAMissingRow_shouldSkipIt() async throws {
    let store = try makeStore()
    let cards = CardFixtures.set(code: "fdn", count: 2)
    try await store.upsert(cards: cards, source: .bulk)

    let loaded = try await store.cards(ids: [cards[0].id, UUID(), cards[1].id])

    #expect(loaded.map(\.id) == [cards[0].id, cards[1].id])
  }

  @Test func whenBrowsingASet_shouldOrderByNameThenCollectorNumber() async throws {
    let store = try makeStore()
    try await store.upsert(
      cards: CardFixtures.set(code: "fdn", count: 3, names: ["Zebra", "Ajani", "Mox"]),
      source: .bulk
    )

    let result = try await store.cards(
      inSet: "fdn", sortMode: .name, sortDirection: .asc, page: 1
    )

    #expect(result.cards.map(\.name) == ["Ajani", "Mox", "Zebra"])
    #expect(result.total == 3)
  }

  @Test func whenBrowsingDescending_shouldReverseTheOrder() async throws {
    let store = try makeStore()
    try await store.upsert(
      cards: CardFixtures.set(code: "fdn", count: 3, names: ["Zebra", "Ajani", "Mox"]),
      source: .bulk
    )

    let result = try await store.cards(
      inSet: "fdn", sortMode: .name, sortDirection: .desc, page: 1
    )

    #expect(result.cards.map(\.name) == ["Zebra", "Mox", "Ajani"])
  }

  @Test func whenBrowsingASet_shouldNotLeakCardsFromOtherSets() async throws {
    let store = try makeStore()
    try await store.upsert(cards: CardFixtures.set(code: "fdn", count: 2), source: .bulk)
    try await store.upsert(cards: CardFixtures.set(code: "mkm", count: 3), source: .bulk)

    let result = try await store.cards(
      inSet: "mkm", sortMode: .name, sortDirection: .asc, page: 1
    )

    #expect(result.cards.count == 3)
    #expect(result.total == 3)
    #expect(result.cards.allSatisfy { $0.set == "mkm" })
  }

  @Test func whenBrowsingBeyondTheFirstPage_shouldOffsetByScryfallsPageSize() async throws {
    let store = try makeStore()
    let count = CardStore.pageSize + 10
    try await store.upsert(cards: CardFixtures.set(code: "fdn", count: count), source: .bulk)

    let first = try await store.cards(
      inSet: "fdn", sortMode: .released, sortDirection: .asc, page: 1
    )
    let second = try await store.cards(
      inSet: "fdn", sortMode: .released, sortDirection: .asc, page: 2
    )

    #expect(first.cards.count == CardStore.pageSize)
    #expect(second.cards.count == 10)
    #expect(first.total == count)
    #expect(Set(first.cards.map(\.id)).isDisjoint(with: Set(second.cards.map(\.id))))
  }

  @Test func whenBrowsingASet_shouldExcludeNonPaperPrintings() async throws {
    let store = try makeStore()
    try await store.upsert(
      cards: [
        CardFixtures.card(name: "Paper", setCode: "fdn", collectorNumber: "1"),
        CardFixtures.card(
          name: "Arena Only", setCode: "fdn", collectorNumber: "2", games: [.arena]
        ),
      ],
      source: .bulk
    )

    let result = try await store.cards(
      inSet: "fdn", sortMode: .name, sortDirection: .asc, page: 1
    )

    #expect(result.cards.map(\.name) == ["Paper"])
    #expect(result.total == 1)
  }

  @Test func whenSortingByPrice_shouldPutPricelessCardsLast() async throws {
    let store = try makeStore()
    try await store.upsert(
      cards: [
        CardFixtures.card(name: "Cheap", collectorNumber: "1", usd: "0.25"),
        CardFixtures.card(name: "Unpriced", collectorNumber: "2", usd: nil),
        CardFixtures.card(name: "Pricey", collectorNumber: "3", usd: "40.00"),
      ],
      source: .bulk
    )

    let result = try await store.cards(
      inSet: "fdn", sortMode: .usd, sortDirection: .asc, page: 1
    )

    #expect(result.cards.map(\.name) == ["Cheap", "Pricey", "Unpriced"])
  }

  @Test func whenSortingByRarity_shouldUseScryfallsOrderNotAlphabetical() async throws {
    let store = try makeStore()
    try await store.upsert(
      cards: [
        CardFixtures.card(name: "M", collectorNumber: "1", rarity: .mythic),
        CardFixtures.card(name: "C", collectorNumber: "2", rarity: .common),
        CardFixtures.card(name: "R", collectorNumber: "3", rarity: .rare),
        CardFixtures.card(name: "B", collectorNumber: "4", rarity: .bonus),
      ],
      source: .bulk
    )

    let result = try await store.cards(
      inSet: "fdn", sortMode: .rarity, sortDirection: .asc, page: 1
    )

    #expect(result.cards.map(\.name) == ["B", "C", "R", "M"])
  }

  @Test func whenUpsertingSets_shouldRoundTripAndDeduplicate() async throws {
    let store = try makeStore()
    let sets = MockGameSetRequestClient.mockSets

    try await store.upsert(sets: sets)
    try await store.upsert(sets: sets)

    let loaded = try await store.allSets()
    #expect(loaded.count == sets.count)
    #expect(Set(loaded.map(\.code)) == Set(sets.map(\.code)))
  }

  @Test func whenNoSetsStored_shouldReportNoFetchDate() async throws {
    let store = try makeStore()

    #expect(try await store.setsFetchedAt() == nil)
  }

  @Test func whenSetsStored_shouldReportTheFetchDate() async throws {
    let store = try makeStore()
    clock.now = Date(timeIntervalSince1970: 1_700_000_000)

    try await store.upsert(sets: MockGameSetRequestClient.mockSets)

    #expect(try await store.setsFetchedAt() == clock.now)
  }

  @Test func whenStoringAPage_shouldReplayTheExactOrdering() async throws {
    let store = try makeStore()
    let ids = (0..<4).map { _ in UUID() }

    try await store.upsert(
      page: CardPageRecord(
        queryKey: "set:fdn", page: 1, cardIDs: ids,
        hasMore: true, totalCards: 400, fetchedAt: Date()
      )
    )

    let loaded = try #require(try await store.page(queryKey: "set:fdn", page: 1))
    #expect(try loaded.orderedCardIDs() == ids)
    #expect(loaded.hasMore)
    #expect(loaded.totalCards == 400)
  }

  @Test func whenInvalidatingAQuery_shouldDropEveryPageOfItOnly() async throws {
    let store = try makeStore()

    for page in 1...3 {
      try await store.upsert(
        page: CardPageRecord(
          queryKey: "set:fdn", page: page, cardIDs: [UUID()],
          hasMore: false, totalCards: 3, fetchedAt: Date()
        )
      )
    }
    try await store.upsert(
      page: CardPageRecord(
        queryKey: "set:mkm", page: 1, cardIDs: [UUID()],
        hasMore: false, totalCards: 1, fetchedAt: Date()
      )
    )

    try await store.invalidatePages(queryKey: "set:fdn")

    #expect(try await store.page(queryKey: "set:fdn", page: 1) == nil)
    #expect(try await store.page(queryKey: "set:fdn", page: 3) == nil)
    #expect(try await store.page(queryKey: "set:mkm", page: 1) != nil)
  }

  @Test func whenANewBuildHasBeenPublished_shouldReportThePageStale() throws {
    let fetchedAt = Date(timeIntervalSince1970: 1_800_000_000)
    let record = try CardPageRecord(
      queryKey: "set:fdn", page: 1, cardIDs: [],
      hasMore: false, totalCards: 0, fetchedAt: fetchedAt
    )

    let afterBoundary = BulkRefreshSchedule
      .nextDailyBoundary(after: fetchedAt)
      .addingTimeInterval(60)

    #expect(record.isStale(since: afterBoundary))
    #expect(record.isStale(since: fetchedAt.addingTimeInterval(60)) == false)
  }

  @Test func whenNoSyncHasRun_shouldReportNoState() async throws {
    let store = try makeStore()

    #expect(try await store.syncState(id: "default_cards") == nil)
  }

  @Test func whenUpsertingSyncState_shouldReplaceTheExistingRow() async throws {
    let store = try makeStore()

    try await store.upsert(
      syncState: SyncStateRecord(
        id: "default_cards", remoteUpdatedAt: "2026-09-01T00:00:00Z",
        status: SyncStateRecord.Status.downloading.rawValue
      )
    )
    try await store.upsert(
      syncState: SyncStateRecord(
        id: "default_cards", remoteUpdatedAt: "2026-09-05T21:05:33.429+00:00",
        ingestedCardCount: 116_129, status: SyncStateRecord.Status.complete.rawValue
      )
    )

    let state = try #require(try await store.syncState(id: "default_cards"))
    #expect(state.remoteUpdatedAt == "2026-09-05T21:05:33.429+00:00")
    #expect(state.hasCompleteCatalog)
  }

  @Test func whenIngestProducedNoCards_shouldNotClaimACompleteCatalog() {
    let state = SyncStateRecord(
      id: "default_cards", ingestedCardCount: 0,
      status: SyncStateRecord.Status.complete.rawValue
    )

    #expect(state.hasCompleteCatalog == false)
  }
}
