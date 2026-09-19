@testable import Networking
import Dependencies
import Foundation
import ScryfallKit
import SQLiteData
import Testing

/// Covers working a printing's pull odds out of MTGJSON's booster configuration, against a trimmed
/// slice of Bloomburrow's real set file. The expected odds were computed from the full file.
struct PullOddsTests {
  private func bloomburrow() throws -> SetPullOdds {
    try JSONDecoder()
      .decode(MTGJSONSetFile.self, from: Data(PullOddsFixtures.bloomburrow.utf8))
      .data
      .pullOdds(setCode: "BLB")
  }

  private func odds(of id: UUID, in set: SetPullOdds) throws -> CardPullOdds {
    let uuid = try #require(set.uuidsByScryfallID[id.uuidString.lowercased()])
    return try #require(CardPullOdds(products: set.oddsByUUID[uuid] ?? []))
  }

  // MARK: - Working the odds out

  @Test func aMythic_shouldComeOutAtItsRealRateInEachProduct() throws {
    let odds = try odds(of: PullOddsFixtures.mahaID, in: bloomburrow())

    #expect(odds.products.map(\.id) == ["blb/play", "blb/collector"])

    let play = odds.products[0]
    #expect(abs(play.chance - 0.005970058363027775) < 1e-12)
    #expect(abs(play.foilChance - 0.00047619047619051896) < 1e-12)
    #expect(abs(play.nonFoilChance - 0.005496485260770956) < 1e-12)
    #expect(play.packs == 168)
    #expect(play.foilPacks == 2_100)
    #expect(play.nonFoilPacks == 182)

    // Every card of a Bloomburrow Collector Booster is a foil but the showcase slots.
    let collector = odds.products[1]
    #expect(collector.packs == 140)
    #expect(collector.foilPacks == 140)
    #expect(collector.nonFoilPacks == nil)
  }

  @Test func aRare_shouldComeOutTwiceAsOftenAsAMythic() throws {
    let odds = try odds(of: PullOddsFixtures.mabelID, in: bloomburrow())

    #expect(odds.headline.packs == 84)
    #expect(odds.products[1].packs == 70)
  }

  @Test func aBorderlessPrinting_shouldCombineEveryLayoutAndSheetItIsOn() throws {
    let odds = try odds(of: PullOddsFixtures.borderlessMahaID, in: bloomburrow())

    // In a Play Booster it rides only on the rare slot's showcase share and the foil slot.
    #expect(odds.headline.packs == 335)
    // A Collector Booster has two layouts and three sheets that can hold it, in both finishes.
    let collector = odds.products[1]
    #expect(abs(collector.chance - 0.01921214078140132) < 1e-12)
    #expect(collector.packs == 52)
    #expect(collector.foilPacks == 163)
    #expect(collector.nonFoilPacks == 76)
  }

  @Test func digitalAndSampleProducts_shouldBeLeftOut() throws {
    let set = try bloomburrow()
    let ids = Set(set.oddsByUUID.values.flatMap { $0.map(\.id) })

    #expect(ids == ["blb/play", "blb/collector"])
  }

  @Test func productNames_shouldDropTheSetsName() throws {
    let odds = try odds(of: PullOddsFixtures.mahaID, in: bloomburrow())

    #expect(odds.products.map(\.name) == ["Play Booster", "Collector Booster"])
    #expect(odds.products.map(\.setName) == ["Bloomburrow", "Bloomburrow"])
  }

  // MARK: - The estimate

  @Test func theEstimate_shouldWeighEachProductByItsShareOfThePacks() throws {
    let set = try bloomburrow()
    let uuid = try #require(set.uuidsByScryfallID[PullOddsFixtures.mahaID.uuidString.lowercased()])
    let odds = try #require(CardPullOdds(products: set.oddsByUUID[uuid] ?? [], setProducts: set.products))

    // The slice sells Play and Collector Boosters, taken as 8 and 1 in every 9 packs opened.
    #expect(odds.mix.map(\.id) == ["blb/play", "blb/collector"])
    #expect(abs(odds.mix[0].share - 8.0 / 9) < 1e-12)
    #expect(abs(odds.mix[1].share - 1.0 / 9) < 1e-12)
    #expect(odds.estimatePacks == 164)
    #expect(odds.isEstimated)
  }

  @Test func theMix_shouldSplitEachKindsShareAndLeaveOutPromos() {
    let mix = PackShare.mix(of: [
      "woe/draft": "Draft Booster",
      "woe/set": "Set Booster",
      "woe/collector": "Collector Booster",
      "woe/prerelease": "Prerelease Promo Pack",
      "woe/bundle-promo": "Bundle Promo Card",
    ])

    #expect(mix.map(\.id) == ["woe/draft", "woe/set", "woe/collector"])
    #expect(abs(mix[0].share - 0.4 / 0.9) < 1e-12)
    #expect(abs(mix[1].share - 0.4 / 0.9) < 1e-12)
    #expect(abs(mix[2].share - 0.1 / 0.9) < 1e-12)
  }

  @Test func aPrintingOnlyInAPromo_shouldBeQuotedAtItsOwnOdds() throws {
    let promo = ProductPullOdds(
      id: "fin/bundle-promo", name: "Bundle Promo Card", setName: "Final Fantasy",
      chance: 1.0 / 80, foilChance: 1.0 / 80, nonFoilChance: 0
    )
    let odds = try #require(CardPullOdds(
      products: [promo],
      setProducts: ["fin/play": "Play Booster", "fin/bundle-promo": "Bundle Promo Card"]
    ))

    #expect(odds.estimatePacks == 80)
    #expect(odds.isEstimated == false)
  }

  // MARK: - Which product leads

  @Test func theHeadline_shouldBeTheProductMostPeopleOpen() throws {
    func product(_ key: String, chance: Double) -> ProductPullOdds {
      ProductPullOdds(id: "set/\(key)", name: key, setName: "Set", chance: chance, foilChance: 0, nonFoilChance: chance)
    }

    let odds = try #require(CardPullOdds(products: [
      product("collector", chance: 0.5),
      product("bundle-promo", chance: 0.01),
      product("theme-g", chance: 0.9),
      product("set", chance: 0.1),
      product("draft", chance: 0.01),
    ]))

    #expect(odds.products.map(\.productKey) == ["draft", "set", "collector", "theme-g", "bundle-promo"])
  }

  @Test func noProducts_shouldMeanNoOdds() {
    #expect(CardPullOdds(products: []) == nil)
  }

  // MARK: - The source

  @Test func aCommanderCard_shouldBeFoundInItsParentSetsCollectorBooster() async throws {
    let (source, _) = try makeSource()
    StubURLProtocol.stub(url("PARENTC"), body: PullOddsFixtures.bloomburrowCommander)
    StubURLProtocol.stub(url("PARENTB"), body: PullOddsFixtures.bloomburrow)

    let odds = await source.odds(for: card(PullOddsFixtures.belloID, set: "parentc"), parentSetCode: "parentb")

    let collector = try #require(odds?.headline)
    #expect(collector.id == "parentb/collector")
    #expect(collector.setName == "Bloomburrow")
    #expect(collector.packs == 71)
    #expect(collector.foilPacks == nil)
    #expect(odds?.products.count == 1)
    // Weighed against every pack of Bloomburrow, most of which never hold a commander card.
    #expect(odds?.estimatePacks == 639)
  }

  @Test func cardsOfOneSet_shouldShareOneDownload() async throws {
    let (source, _) = try makeSource()
    StubURLProtocol.stub(url("SHAREDB"), body: PullOddsFixtures.bloomburrow)

    async let maha = source.odds(for: card(PullOddsFixtures.mahaID, set: "sharedb"), parentSetCode: nil)
    async let mabel = source.odds(for: card(PullOddsFixtures.mabelID, set: "sharedb"), parentSetCode: nil)
    let results = await [maha, mabel]
    let borderless = await source.odds(for: card(PullOddsFixtures.borderlessMahaID, set: "sharedb"), parentSetCode: nil)

    #expect(results.map { $0?.headline.packs } == [168, 84])
    #expect(borderless?.headline.packs == 335)
    #expect(StubURLProtocol.requestCount(for: url("SHAREDB")) == 1)
  }

  @Test func aSetMTGJSONDoesNotCarry_shouldHaveNoOddsAndNotBeAskedForAgain() async throws {
    let (source, database) = try makeSource()
    StubURLProtocol.stub(url("MISSING"), status: 404)

    let odds = await source.odds(for: card(PullOddsFixtures.mahaID, set: "missing"), parentSetCode: nil)

    #expect(odds == nil)
    let stored = try await storedRecord("missing", in: database)
    #expect(stored?.odds == .empty)
  }

  @Test func aSetFileThatWillNotDecode_shouldHaveNoOddsAndNotBeAskedForAgain() async throws {
    let (source, database) = try makeSource()
    StubURLProtocol.stub(url("GARBLED"), body: "{ not a set file")

    let odds = await source.odds(for: card(PullOddsFixtures.mahaID, set: "garbled"), parentSetCode: nil)

    #expect(odds == nil)
    let stored = try await storedRecord("garbled", in: database)
    #expect(stored?.odds == .empty)
  }

  @Test func aFailedDownload_shouldHaveNoOddsAndStoreNothing() async throws {
    let (source, database) = try makeSource()
    StubURLProtocol.stub(url("FAILED"), status: 500)

    let odds = await source.odds(for: card(PullOddsFixtures.mahaID, set: "failed"), parentSetCode: nil)

    #expect(odds == nil)
    let stored = try await storedRecord("failed", in: database)
    #expect(stored == nil)
  }

  @Test func storedOdds_shouldBeUsedWithoutTheNetworkWhileFresh() async throws {
    let (source, database) = try makeSource()
    let odds = try bloomburrow()
    let record = try SetPullOddsRecord(setCode: "stored", odds: odds, fetchedAt: now.addingTimeInterval(-60 * 60 * 24))
    try await database.write { connection in
      try SetPullOddsRecord.insert { record }.execute(connection)
    }

    let result = await source.odds(for: card(PullOddsFixtures.mahaID, set: "stored"), parentSetCode: nil)

    #expect(result?.headline.packs == 168)
    #expect(StubURLProtocol.requestCount(for: url("STORED")) == 0)
  }

  @Test func aCardFromASetNotOutYet_shouldHaveNoOddsAndNotBeDownloaded() async throws {
    let (source, _) = try makeSource()
    StubURLProtocol.stub(url("UPCOMING"), body: PullOddsFixtures.bloomburrow)
    var upcoming = card(PullOddsFixtures.mahaID, set: "upcoming")
    upcoming.releasedAt = "2026-06-01"

    let odds = await source.odds(for: upcoming, parentSetCode: nil)

    #expect(odds == nil)
    #expect(StubURLProtocol.requestCount(for: url("UPCOMING")) == 0)
  }

  @Test func aCardReleasedToday_shouldHaveItsOdds() async throws {
    let (source, _) = try makeSource()
    StubURLProtocol.stub(url("TODAY"), body: PullOddsFixtures.bloomburrow)
    var today = card(PullOddsFixtures.mahaID, set: "today")
    today.releasedAt = "2026-05-28"

    let odds = await source.odds(for: today, parentSetCode: nil)

    #expect(odds?.headline.packs == 168)
  }

  @Test func aDigitalPrinting_shouldHaveNoOdds() async throws {
    let (source, _) = try makeSource()
    StubURLProtocol.stub(url("DIGITAL"), body: PullOddsFixtures.bloomburrow)
    var digital = card(PullOddsFixtures.mahaID, set: "digital")
    digital.digital = true

    let odds = await source.odds(for: digital, parentSetCode: nil)

    #expect(odds == nil)
    #expect(StubURLProtocol.requestCount(for: url("DIGITAL")) == 0)
  }

  // MARK: - Helpers

  /// Midday on 28 May 2026, well after the fixture cards' release.
  private let now = Date(timeIntervalSince1970: 1_779_969_600)

  private func storedRecord(_ id: String, in database: any DatabaseWriter) async throws -> SetPullOddsRecord? {
    try await database.read { connection in
      try #sql(
        """
        SELECT \(SetPullOddsRecord.columns) FROM "setPullOdds" WHERE "id" = \(bind: id) LIMIT 1
        """,
        as: SetPullOddsRecord.self
      )
      .fetchOne(connection)
    }
  }

  private func url(_ code: String) -> URL {
    URL(string: "https://mtgjson.com/api/v5/\(code).json")!
  }

  private func card(_ id: UUID, set: String) -> Card {
    CardFixtures.card(id: id, name: "Card", setCode: set, collectorNumber: "1", rarity: .mythic)
  }

  /// A source over its own in-memory database, on `now`.
  private func makeSource() throws -> (MTGJSONCardPullOddsSource, any DatabaseWriter) {
    let database = try makeTestDatabase()
    let source = withDependencies {
      $0.context = .test
      $0.defaultDatabase = database
      $0.date = .constant(now)
    } operation: {
      MTGJSONCardPullOddsSource(session: StubURLProtocol.session())
    }
    return (source, database)
  }
}
