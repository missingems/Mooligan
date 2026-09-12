@testable import Networking
import Dependencies
import Foundation
import ScryfallKit
import Testing

/// Covers `CardStore.boosterPool(inSet:)`'s fallback when a set's cards all
/// read `booster: false` — the state Scryfall's real data is in for Star Trek,
/// Marvel Super Heroes, The Hobbit and Secrets of Strixhaven, which otherwise
/// left "Couldn't open that pack" as the only outcome for a product the app's
/// own shelf was still offering.
struct CardStoreBoosterTests {
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

  private func seed(
    _ store: CardStore,
    setCode: String,
    booster: Bool
  ) async throws {
    func cards(rarity: Card.Rarity, count: Int, prefix: String) -> [Card] {
      (1...count).map { index in
        var card = CardFixtures.card(
          name: "\(prefix) \(index)",
          setCode: setCode,
          collectorNumber: "\(index)",
          rarity: rarity
        )
        card.booster = booster
        return card
      }
    }

    try await store.upsert(
      cards: cards(rarity: .common, count: 10, prefix: "Common")
        + cards(rarity: .uncommon, count: 5, prefix: "Uncommon")
        + cards(rarity: .rare, count: 3, prefix: "Rare"),
      source: .bulk
    )
  }

  @Test("a set marked booster:true on every card rolls normally")
  func normalSetUsesTheStrictFilter() async throws {
    let store = try makeStore()
    try await seed(store, setCode: "nrm", booster: true)

    let pool = try await store.boosterPool(inSet: "nrm")

    #expect(pool.isUsable)
    #expect(pool.commons.isEmpty == false)
  }

  @Test("a set marked booster:false on every card still produces a pool")
  func allBoosterFalseSetFallsBackToUsable() async throws {
    let store = try makeStore()
    try await seed(store, setCode: "sos", booster: false)

    let pool = try await store.boosterPool(inSet: "sos")

    #expect(pool.isUsable)
    #expect(pool.commons.isEmpty == false)
    #expect(pool.rares.isEmpty == false)
  }

  @Test("a set with nothing in the database at all is still unusable")
  func emptySetStaysUnusable() async throws {
    let store = try makeStore()

    let pool = try await store.boosterPool(inSet: "xyz")

    #expect(pool.isUsable == false)
  }
}
