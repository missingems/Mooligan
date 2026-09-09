@testable import Networking
import Foundation
import ScryfallKit
import Testing

/// A Collector Booster draws from more than the set on the wrapper.
///
/// The numbers asserted against here were read out of MTGJSON's own booster
/// configuration for two real sets:
///
/// - The Hobbit (HOB): the collector `boosterfun` sheet holds 132 cards, 66 of
///   them from The Hobbit Eternal (HOC) — 54 mythic, 12 rare — and the box
///   topper sheet is 40 cards, every one of them HOC. Its Play Booster sheets
///   are HOB and nothing else.
/// - Bloomburrow (BLB): the collector booster has a 40-card `commanderCard`
///   sheet drawn entirely from Bloomburrow Commander (BLC) — 29 rare, 11 mythic
///   — plus a 4-card `foilCommander` sheet and another 28 BLC cards among the
///   showcase rares. Its Play Booster is BLB apart from a ten-card Special
///   Guests sheet.
///
/// Two things follow, and are what these tests pin down: companions belong to
/// the Collector Booster only, and every companion card on a real sheet is a
/// rare or a mythic.
@Suite("Collector booster companion pools")
struct BoosterCompanionPoolTests {
  private func set(
    code: String,
    name: String,
    type: MTGSet.Kind,
    parent: String? = nil,
    cardCount: Int = 300,
    digital: Bool = false
  ) -> MTGSet {
    MTGSet(
      id: UUID(), code: code, name: name, setType: type, releasedAt: "2026-08-14",
      parentSetCode: parent, cardCount: cardCount, digital: digital,
      foilOnly: false, nonfoilOnly: false,
      scryfallUri: "", uri: "", iconSvgUri: "", searchUri: ""
    )
  }

  private var hobbit: MTGSet { set(code: "hob", name: "The Hobbit", type: .expansion) }

  private var sets: [MTGSet] {
    [
      hobbit,
      set(code: "hoc", name: "The Hobbit Eternal", type: .eternal, parent: "hob", cardCount: 158),
      set(code: "thob", name: "The Hobbit Tokens", type: .token, parent: "hob", cardCount: 15),
      set(code: "blb", name: "Bloomburrow", type: .expansion),
      set(code: "blc", name: "Bloomburrow Commander", type: .commander, parent: "blb"),
      set(code: "spg", name: "Special Guests", type: .masterpiece),
    ]
  }

  // MARK: - Which sets count as companions

  @Test("an eternal set printed alongside a set is one of its companions")
  func findsTheEternalSet() {
    #expect(hobbit.companionSetCodes(in: sets) == ["hoc"])
  }

  @Test("a commander set printed alongside a set is one of its companions")
  func findsTheCommanderSet() {
    let bloomburrow = sets.first { $0.code == "blb" }!
    #expect(bloomburrow.companionSetCodes(in: sets) == ["blc"])
  }

  @Test("tokens, and sets belonging to nobody, are not companions")
  func ignoresUnrelatedSets() {
    // `thob` is a child of `hob` but is a token set; `spg` is a real part of
    // Bloomburrow's collector booster but Scryfall files it with no parent, so
    // it is out of reach here. Both must stay out.
    let companions = hobbit.companionSetCodes(in: sets)
    #expect(companions.contains("thob") == false)
    #expect(companions.contains("spg") == false)
  }

  @Test("a set with nothing printed alongside it has no companions")
  func handlesASetOnItsOwn() {
    let guests = sets.first { $0.code == "spg" }!
    #expect(guests.companionSetCodes(in: sets).isEmpty)
  }

  // MARK: - What a companion contributes

  private func pool(setCode: String, counts: BoosterRarityCounts) -> BoosterCardPool {
    BoosterCardPool(
      commons: MockBoosterPoolSource.cards(rarity: .common, count: counts.common, setCode: setCode),
      uncommons: MockBoosterPoolSource.cards(
        rarity: .uncommon, count: counts.uncommon, setCode: setCode
      ),
      rares: MockBoosterPoolSource.cards(rarity: .rare, count: counts.rare, setCode: setCode),
      mythics: MockBoosterPoolSource.cards(rarity: .mythic, count: counts.mythic, setCode: setCode),
      lands: MockBoosterPoolSource.cards(
        rarity: .common, count: counts.land, setCode: setCode, namePrefix: "Island"
      ),
      rarityCounts: counts
    )
  }

  @Test("a companion contributes its rares and mythics")
  func mergesTheTopRarities() {
    var main = pool(
      setCode: "hob",
      counts: BoosterRarityCounts(common: 40, uncommon: 20, rare: 12, mythic: 5, land: 5)
    )
    let companion = pool(
      setCode: "hoc",
      counts: BoosterRarityCounts(common: 8, uncommon: 8, rare: 12, mythic: 54, land: 0)
    )

    main.merge(companion, keeping: [.rare, .mythic])

    #expect(main.rares.count == 24)
    #expect(main.mythics.count == 54 + 5)
    #expect(main.rares.contains { $0.set == "hoc" })
    #expect(main.mythics.contains { $0.set == "hoc" })
  }

  @Test("a companion's commons and uncommons stay out of the pack")
  func leavesTheLowerRaritiesAlone() {
    var main = pool(
      setCode: "hob",
      counts: BoosterRarityCounts(common: 40, uncommon: 20, rare: 12, mythic: 5, land: 5)
    )
    let companion = pool(
      setCode: "hoc",
      counts: BoosterRarityCounts(common: 8, uncommon: 8, rare: 12, mythic: 54, land: 3)
    )

    main.merge(companion, keeping: [.rare, .mythic])

    #expect(main.commons.count == 40)
    #expect(main.uncommons.count == 20)
    #expect(main.lands.count == 5)
    #expect(main.commons.contains { $0.set == "hoc" } == false)
  }

  @Test("pull odds are quoted against the wider pool")
  func growsTheDenominators() {
    var main = pool(
      setCode: "blb",
      counts: BoosterRarityCounts(common: 40, uncommon: 20, rare: 12, mythic: 5, land: 5)
    )
    let companion = pool(
      setCode: "blc",
      counts: BoosterRarityCounts(common: 8, uncommon: 8, rare: 29, mythic: 11, land: 0)
    )

    main.merge(companion, keeping: [.rare, .mythic])

    #expect(main.rarityCounts?.rare == 41)
    #expect(main.rarityCounts?.mythic == 16)
    // Untouched, because their cards were not taken either.
    #expect(main.rarityCounts?.common == 40)
    #expect(main.rarityCounts?.uncommon == 20)
  }

  // MARK: - Which product gets them

  private struct StubPoolSource: BoosterPoolSource {
    let counts: [String: BoosterRarityCounts]

    func pool(forSet setCode: String) async throws -> BoosterCardPool {
      guard let counts = counts[setCode.lowercased()] else {
        throw BoosterPoolSourceError.emptyPool(setCode: setCode)
      }

      return BoosterCardPool(
        commons: MockBoosterPoolSource.cards(
          rarity: .common, count: counts.common, setCode: setCode
        ),
        uncommons: MockBoosterPoolSource.cards(
          rarity: .uncommon, count: counts.uncommon, setCode: setCode
        ),
        rares: MockBoosterPoolSource.cards(rarity: .rare, count: counts.rare, setCode: setCode),
        mythics: MockBoosterPoolSource.cards(
          rarity: .mythic, count: counts.mythic, setCode: setCode
        ),
        lands: MockBoosterPoolSource.cards(
          rarity: .common, count: counts.land, setCode: setCode, namePrefix: "Island"
        ),
        rarityCounts: counts
      )
    }
  }

  private var stub: StubPoolSource {
    StubPoolSource(counts: [
      "hob": BoosterRarityCounts(common: 40, uncommon: 20, rare: 12, mythic: 5, land: 5),
      "hoc": BoosterRarityCounts(common: 0, uncommon: 0, rare: 12, mythic: 54, land: 0),
    ])
  }

  @Test("asking for no companions leaves the pool as the set's own")
  func playBoosterPoolIsTheSetAlone() async throws {
    let pool = try await stub.pool(forSet: "hob", companions: [])

    #expect(pool.rares.count == 12)
    #expect(pool.mythics.count == 5)
  }

  @Test("asking for companions widens the pool")
  func collectorPoolReachesTheCompanion() async throws {
    let pool = try await stub.pool(forSet: "hob", companions: ["hoc"])

    #expect(pool.rares.count == 24)
    #expect(pool.mythics.count == 59)
  }

  @Test("a companion that cannot be read does not fail the open")
  func survivesAnUnreadableCompanion() async throws {
    let pool = try await stub.pool(forSet: "hob", companions: ["nope", "hoc"])

    #expect(pool.rares.count == 24)
    #expect(pool.mythics.count == 59)
  }
}
