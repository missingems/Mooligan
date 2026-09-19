@testable import CardDetail
import Foundation
import Networking
import ScryfallKit
import Testing

struct InformationWidgetInsightTests {
  private func product(
    _ key: String,
    setName: String = "Bloomburrow",
    packs: Double,
    foilPacks: Double?,
    nonFoilPacks: Double?
  ) -> ProductPullOdds {
    ProductPullOdds(
      id: "blb/\(key)",
      name: key == "play" ? "Play Booster" : "Collector Booster",
      setName: setName,
      chance: 1 / packs,
      foilChance: foilPacks.map { 1 / $0 } ?? 0,
      nonFoilChance: nonFoilPacks.map { 1 / $0 } ?? 0
    )
  }

  private var card: Card {
    var card = Card.mock(name: "Maha, Its Feathers Night", collectorNumber: "100", set: "blb")
    card.setName = "Bloomburrow"
    card.rarity = .mythic
    card.manaCost = "{3}{B}{B}"
    card.typeLine = "Legendary Creature — Elemental Bird"
    card.oracleText = "Flying, trample"
    return card
  }

  @Test func pullOdds_shouldLeadWithTheEstimateThenEachProductsOwnOdds() throws {
    let odds = try #require(CardPullOdds(
      products: [
        product("collector", packs: 140, foilPacks: 140, nonFoilPacks: nil),
        product("play", packs: 168, foilPacks: 2_100, nonFoilPacks: 182),
      ],
      setProducts: ["blb/play": "Play Booster", "blb/collector": "Collector Booster"]
    ))

    let groups = InformationWidget.pullOdds(odds, rarity: .mythic, tilt: 5).insightFactGroups(card: card, faceDirection: nil)

    #expect(groups.map(\.header) == ["Estimate", "Play Booster", "Collector Booster"])
    // Play Boosters taken as 8 in 9 packs opened and Collector Boosters as 1 in 9.
    #expect(groups[0].facts.map(\.title) == ["Any Bloomburrow pack"])
    #expect(groups[0].facts.map(\.value) == ["~164 packs"])
    #expect(groups[0].footer == "A guess across Bloomburrow's packs, taking the packs opened to be about 89% Play Boosters and 11% Collector Boosters. Each product's own odds are below.")
    // One number to a row, each with its own name.
    #expect(groups[1].facts.map(\.title) == ["Any finish", "Foil", "Non-foil"])
    #expect(groups[1].facts.map(\.value) == ["~168 packs", "~2,100 packs", "~182 packs"])
    #expect(groups[2].facts.map(\.title) == ["Foil only"])
    #expect(groups[2].facts.map(\.value) == ["~140 packs"])
  }

  @Test func aPromoOnlyPrinting_shouldShowItsOwnOddsWithoutAnEstimate() throws {
    // Only in the prerelease pack, which is no part of the Play and Collector Booster mix.
    let odds = try #require(CardPullOdds(
      products: [
        ProductPullOdds(
          id: "blb/prerelease", name: "Prerelease Promo Pack", setName: "Bloomburrow",
          chance: 1.0 / 70, foilChance: 1.0 / 70, nonFoilChance: 0
        ),
      ],
      setProducts: ["blb/play": "Play Booster", "blb/collector": "Collector Booster", "blb/prerelease": "Prerelease Promo Pack"]
    ))

    let widget = InformationWidget.pullOdds(odds, rarity: .rare, tilt: 5)
    let groups = widget.insightFactGroups(card: card, faceDirection: nil)

    #expect(groups.map(\.header) == ["Prerelease Promo Pack"])
    #expect(groups[0].facts.map(\.value) == ["~70 packs"])
    #expect(widget.insightPrompt(card: card).contains("Estimated across") == false)
  }

  @Test func pullOddsFromAParentSet_shouldNameThatSet() throws {
    var commanderCard = card
    commanderCard.setName = "Bloomburrow Commander"
    let odds = try #require(CardPullOdds(products: [
      product("collector", packs: 71, foilPacks: nil, nonFoilPacks: 71),
    ]))

    let groups = InformationWidget.pullOdds(odds, rarity: .mythic, tilt: 5).insightFactGroups(card: commanderCard, faceDirection: nil)

    #expect(groups.map(\.header) == ["Estimate", "Bloomburrow Collector Booster"])
    #expect(groups[1].facts.map(\.title) == ["Non-foil only"])
  }

  @Test func thePullOddsPrompt_shouldGiveTheModelEveryNumberAndTheCard() throws {
    let odds = try #require(CardPullOdds(products: [
      product("play", packs: 168, foilPacks: 2_100, nonFoilPacks: 182),
    ]))

    let prompt = InformationWidget.pullOdds(odds, rarity: .mythic, tilt: 5).insightPrompt(card: card)

    #expect(prompt.contains("Definition: How many packs you would open"))
    #expect(prompt.contains(
      "- Bloomburrow Play Booster: one pack in 168 holds it in either finish."
        + " Counting only foils: one pack in 2,100. Counting only non-foils: one pack in 182."
    ))
    #expect(prompt.contains("It turns up most often in the Bloomburrow Play Booster."))
    #expect(prompt.contains("- Estimated across every kind of Bloomburrow pack, weighted by a guess at how many of each are opened: one pack in 168."))
    #expect(prompt.contains("Name: Maha, Its Feathers Night"))
    #expect(prompt.contains("Mana cost: {3}{B}{B}"))
    #expect(prompt.contains("Rules text: Flying, trample"))
    #expect(prompt.contains("Rarity: mythic"))
    #expect(prompt.hasSuffix("do not repeat, round or calculate any number or percentage."))
  }

  @Test func aDoubleFacedCard_shouldDescribeEachFace() {
    var card = card
    card.manaCost = nil
    card.cardFaces = [
      Card.Face(manaCost: "{1}{G}", name: "Front", oracleText: "Transform it."),
      Card.Face(manaCost: "", name: "Back"),
    ]

    let description = card.insightDescription

    #expect(description.contains("Face 1: Front\n  Mana cost: {1}{G}\n  Rules text: Transform it."))
    #expect(description.contains("Face 2: Back"))
  }

  @Test func theCollectorNumber_shouldNameThePrintingsTreatment() {
    var borderless = card
    borderless.borderColor = .borderless
    borderless.frameEffects = [.showcase]

    let facts = InformationWidget.collectorNumber("289").insightFactGroups(card: borderless, faceDirection: nil)[0].facts

    #expect(facts.map(\.value) == ["#289", "Bloomburrow", "Borderless and Showcase"])
  }

  @Test func aColorlessCardWithNoCost_shouldOnlyShowItsIdentity() {
    var land = card
    land.manaCost = nil
    land.colorIdentity = []

    let facts = InformationWidget.colorIdentity(["{C}"]).insightFactGroups(card: land, faceDirection: nil)[0].facts

    #expect(facts.map(\.title) == ["Identity"])
    #expect(facts.map(\.value) == ["Colorless"])
  }

  @Test func theManaValue_shouldReadAsAWholeNumber() {
    let facts = InformationWidget.manaValue("5.0").insightFactGroups(card: card, faceDirection: nil)[0].facts

    #expect(facts.first?.value == "5")
    #expect(facts.last?.symbols == ["{3}", "{B}", "{B}"])
    #expect(InformationWidget.manaValue("5.0").insightPrompt(card: card).contains("Its mana value is 5."))
  }
}
