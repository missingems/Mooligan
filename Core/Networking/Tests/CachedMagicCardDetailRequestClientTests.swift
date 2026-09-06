@testable import Networking
import Dependencies
import Foundation
import ScryfallKit
import SQLiteData
import Testing

struct CachedMagicCardDetailRequestClientTests {
  private struct Harness {
    let client: CachedMagicCardDetailRequestClient
    let remote: SpyCardDetailRequestClient
    let store: CardStore
    let clock: TestClock
  }

  private func makeHarness() throws -> Harness {
    let database = try makeTestDatabase()
    let remote = SpyCardDetailRequestClient()
    let clock = TestClock()

    let (client, store) = withDependencies {
      $0.context = .test
      $0.defaultDatabase = database
      $0.date = .init { clock.now }
      $0.remoteCardDetailRequestClient = remote
    } operation: {
      (CachedMagicCardDetailRequestClient(), CardStore())
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

  @Test func whenTheSetIsCached_shouldNotHitTheNetwork() async throws {
    let harness = try makeHarness()
    let set = MockGameSetRequestClient.mockSets[0]
    try await harness.store.upsert(sets: [set])
    let card = CardFixtures.card(setCode: set.code)

    let loaded = try await harness.client.getSet(of: card)

    #expect(harness.remote.getSetCount == 0)
    #expect(loaded.code == set.code)
  }

  @Test func whenTheSetIsNotCached_shouldFetchAndStoreIt() async throws {
    let harness = try makeHarness()
    let set = MockGameSetRequestClient.mockSets[0]
    harness.remote.setSet(set)

    let loaded = try await harness.client.getSet(of: CardFixtures.card(setCode: set.code))

    #expect(harness.remote.getSetCount == 1)
    #expect(loaded.code == set.code)
    #expect(try await harness.store.set(code: set.code) != nil)
  }

  @Test func whenVariantsWereFetchedBefore_shouldReplayThemWithoutARequest() async throws {
    let harness = try makeHarness()
    let card = CardFixtures.card(oracleID: "oracle-1")
    let variants = (0..<3).map {
      CardFixtures.card(name: "Printing \($0)", collectorNumber: "\($0)", oracleID: "oracle-1")
    }
    harness.remote.setVariants(variants)

    _ = try await harness.client.getVariants(of: card, page: 1)
    let second = try await harness.client.getVariants(of: card, page: 1)

    #expect(harness.remote.getVariantsCount == 1)
    #expect(second.data.map(\.id) == variants.map(\.id))
  }

  @Test func whenTheCatalogIsComplete_shouldListVariantsWithoutARequest() async throws {
    let harness = try makeHarness()
    let card = CardFixtures.card(oracleID: "oracle-1")
    let variants = [
      CardFixtures.card(name: "Newest", collectorNumber: "1", releasedAt: "2025-01-01", oracleID: "oracle-1"),
      CardFixtures.card(name: "Oldest", collectorNumber: "2", releasedAt: "2001-01-01", oracleID: "oracle-1"),
      CardFixtures.card(name: "Middle", collectorNumber: "3", releasedAt: "2015-01-01", oracleID: "oracle-1"),
    ]
    try await harness.store.upsert(cards: variants, source: .bulk)
    try await markCatalogComplete(harness.store, cards: variants.count)

    let result = try await harness.client.getVariants(of: card, page: 1)

    #expect(harness.remote.getVariantsCount == 0)
    #expect(result.data.map(\.name) == ["Newest", "Middle", "Oldest"])
    #expect(result.totalCards == 3)
  }

  @Test func whenTheCardHasNoOracleID_shouldThrow() async throws {
    let harness = try makeHarness()
    var card = CardFixtures.card()
    card.oracleId = nil

    await #expect(throws: MagicCardDetailRequestClientError.self) {
      _ = try await harness.client.getVariants(of: card, page: 1)
    }
  }

  @Test func whenEveryRelatedPartIsCached_shouldNotSpendARequestEach() async throws {
    let harness = try makeHarness()
    let token = CardFixtures.card(name: "Goblin Token", oracleID: "token-oracle")
    let meld = CardFixtures.card(name: "Other Token", oracleID: "token-oracle-2")
    try await harness.store.upsert(cards: [token, meld], source: .bulk)

    var card = CardFixtures.card(oracleID: "parent-oracle")
    card.allParts = [token, meld].map {
      Card.RelatedCard(
        id: $0.id, component: .token, name: $0.name, typeLine: "Token", uri: ""
      )
    }

    let result = try await harness.client.getRelatedCardsIfNeeded(of: card, for: .token)

    #expect(harness.remote.getRelatedCount == 0)
    #expect(result?.cardDetails.count == 2)
  }

  @Test func whenOnlySomePartsAreCached_shouldFallBackRatherThanShowAShortList() async throws {
    let harness = try makeHarness()
    let known = CardFixtures.card(name: "Known Token", oracleID: "token-oracle")
    try await harness.store.upsert(cards: [known], source: .bulk)

    var card = CardFixtures.card(oracleID: "parent-oracle")
    card.allParts = [
      Card.RelatedCard(id: known.id, component: .token, name: known.name, typeLine: "Token", uri: ""),
      Card.RelatedCard(id: UUID(), component: .token, name: "Missing", typeLine: "Token", uri: ""),
    ]
    harness.remote.setRelated(
      CardDataSource(cards: [known], hasNextPage: false, total: 1)
    )

    _ = try await harness.client.getRelatedCardsIfNeeded(of: card, for: .token)

    #expect(harness.remote.getRelatedCount == 1)
  }

  @Test func whenARelatedPartSharesTheOracleID_shouldExcludeIt() async throws {
    let harness = try makeHarness()
    let sameCard = CardFixtures.card(name: "Itself", oracleID: "parent-oracle")
    let token = CardFixtures.card(name: "Goblin", oracleID: "token-oracle")
    try await harness.store.upsert(cards: [sameCard, token], source: .bulk)

    var card = CardFixtures.card(oracleID: "parent-oracle")
    card.allParts = [sameCard, token].map {
      Card.RelatedCard(id: $0.id, component: .token, name: $0.name, typeLine: "Token", uri: "")
    }

    let result = try await harness.client.getRelatedCardsIfNeeded(of: card, for: .token)

    #expect(result?.cardDetails.map(\.card.name) == ["Goblin"])
  }

  @Test func whenARelatedPartIsArenaOnly_shouldExcludeIt() async throws {
    let harness = try makeHarness()
    let paper = CardFixtures.card(name: "Paper Token", oracleID: "t1")
    let arena = CardFixtures.card(name: "Arena Token", games: [.arena], oracleID: "t2")
    try await harness.store.upsert(cards: [paper, arena], source: .api)

    var card = CardFixtures.card(oracleID: "parent-oracle")
    card.allParts = [paper, arena].map {
      Card.RelatedCard(id: $0.id, component: .token, name: $0.name, typeLine: "Token", uri: "")
    }

    let result = try await harness.client.getRelatedCardsIfNeeded(of: card, for: .token)

    #expect(result?.cardDetails.map(\.card.name) == ["Paper Token"])
  }

  @Test func whenThereAreNoRelatedParts_shouldReturnNothingWithoutARequest() async throws {
    let harness = try makeHarness()

    let result = try await harness.client.getRelatedCardsIfNeeded(
      of: CardFixtures.card(), for: .token
    )

    #expect(result == nil)
    #expect(harness.remote.getRelatedCount == 0)
  }

  @Test func whenAskingForRulings_shouldAlwaysGoLive() async throws {
    let harness = try makeHarness()

    _ = try await harness.client.getRulings(of: CardFixtures.card())
    _ = try await harness.client.getRulings(of: CardFixtures.card())

    #expect(harness.remote.getRulingsCount == 2)
  }
}
