@testable import Networking
import Foundation
import ScryfallKit
import Testing

@Suite("Booster pack rolling")
struct BoosterPackRollerTests {
  private func pool(
    commons: Int = 40,
    uncommons: Int = 20,
    rares: Int = 12,
    mythics: Int = 5,
    lands: Int = 5
  ) -> BoosterCardPool {
    BoosterCardPool(
      commons: MockBoosterPoolSource.cards(rarity: .common, count: commons, setCode: "tst"),
      uncommons: MockBoosterPoolSource.cards(rarity: .uncommon, count: uncommons, setCode: "tst"),
      rares: MockBoosterPoolSource.cards(rarity: .rare, count: rares, setCode: "tst"),
      mythics: MockBoosterPoolSource.cards(rarity: .mythic, count: mythics, setCode: "tst"),
      lands: MockBoosterPoolSource.cards(
        rarity: .common,
        count: lands,
        setCode: "tst",
        namePrefix: "Island"
      )
    )
  }

  @Test("every slot of every configuration is filled")
  func fillsEverySlot() {
    for kind in BoosterPackKind.allCases {
      var generator = SeededRandomNumberGenerator(seed: 42)
      let cards = BoosterPackRoller.roll(kind: kind, from: pool(), using: &generator)

      #expect(cards.count == kind.cardCount)
    }
  }

  @Test("the same seed always rolls the same pack")
  func isDeterministic() {
    let shared = pool()
    var first = SeededRandomNumberGenerator(seed: 7)
    var second = SeededRandomNumberGenerator(seed: 7)

    let left = BoosterPackRoller.roll(kind: .play, from: shared, using: &first)
    let right = BoosterPackRoller.roll(kind: .play, from: shared, using: &second)

    #expect(left.map(\.card.id) == right.map(\.card.id))
    #expect(left.map(\.isFoil) == right.map(\.isFoil))
  }

  @Test("the mock pool is itself reproducible, so a seeded pack always matches")
  func mockPoolIsStable() async throws {
    let source = MockBoosterPoolSource()
    let first = try await source.pool(forSet: "tst")
    let second = try await source.pool(forSet: "tst")

    #expect(first.commons.map(\.id) == second.commons.map(\.id))
  }

  @Test("a play booster always contains a rare or better")
  func alwaysHasARare() {
    for seed in UInt64(0)..<40 {
      var generator = SeededRandomNumberGenerator(seed: seed)
      let cards = BoosterPackRoller.roll(kind: .play, from: pool(), using: &generator)

      #expect(cards.contains { $0.slot == .rareOrMythic })
      #expect(cards.contains { $0.rarity == .rare || $0.rarity == .mythic })
    }
  }

  @Test("no card is repeated while the pool has room")
  func drawsWithoutReplacement() {
    var generator = SeededRandomNumberGenerator(seed: 99)
    let cards = BoosterPackRoller.roll(kind: .play, from: pool(), using: &generator)

    #expect(Set(cards.map(\.card.id)).count == cards.count)
  }

  @Test("a set with no mythics still produces a full pack")
  func toleratesMissingRarities() {
    var generator = SeededRandomNumberGenerator(seed: 3)
    let cards = BoosterPackRoller.roll(
      kind: .play,
      from: pool(mythics: 0),
      using: &generator
    )

    #expect(cards.count == BoosterPackKind.play.cardCount)
    #expect(cards.contains { $0.rarity == .mythic } == false)
  }

  @Test("the foil wildcard slot is always foil, and plain commons never are")
  func honoursFoilRates() {
    var generator = SeededRandomNumberGenerator(seed: 11)
    let cards = BoosterPackRoller.roll(kind: .play, from: pool(), using: &generator)

    #expect(cards.filter { $0.slot == .foilWildcard }.allSatisfy { $0.isFoil })
    #expect(cards.filter { $0.slot == .common }.allSatisfy { $0.isFoil == false })
  }

  @Test("a collector booster comes back entirely foil except its rare slots")
  func collectorIsShiny() {
    var generator = SeededRandomNumberGenerator(seed: 5)
    let cards = BoosterPackRoller.roll(kind: .collector, from: pool(), using: &generator)

    #expect(cards.filter { $0.slot != .rareOrMythic }.allSatisfy { $0.isFoil })
  }

  @Test("the wildcard and foil wildcard slots draw from their own odds, not a shared table")
  func wildcardAndFoilWildcardAreIndependent() {
    // Distinct enough that reading the wrong table is unmistakable: an all-
    // common wildcard next to an all-mythic foil wildcard.
    let odds = BoosterPackOdds(
      mythicChance: 1.0 / 7.0,
      wildcardWeights: [RarityWeight(rarity: .common, weight: 1.0)],
      foilWildcardWeights: [RarityWeight(rarity: .mythic, weight: 1.0)]
    )

    for seed in UInt64(0)..<20 {
      var generator = SeededRandomNumberGenerator(seed: seed)
      let cards = BoosterPackRoller.roll(kind: .play, from: pool(), odds: odds, using: &generator)

      #expect(cards.first { $0.slot == .wildcard }?.rarity == .common)
      #expect(cards.first { $0.slot == .foilWildcard }?.rarity == .mythic)
    }
  }

  @Test("odds default to the fallback table when the caller supplies none")
  func defaultsToFallbackOdds() {
    var withDefault = SeededRandomNumberGenerator(seed: 21)
    var withExplicitFallback = SeededRandomNumberGenerator(seed: 21)

    let left = BoosterPackRoller.roll(kind: .play, from: pool(), using: &withDefault)
    let right = BoosterPackRoller.roll(
      kind: .play,
      from: pool(),
      odds: .fallback,
      using: &withExplicitFallback
    )

    #expect(left.map(\.card.id) == right.map(\.card.id))
  }
}
