@testable import CardDetail
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct ContentTests {
  private let card = Card.mock()

  private var queryType: QueryType {
    .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
  }

  private var content: Content {
    Content(card: card, queryType: queryType)
  }

  // The sections that load in now live on the feature's state rather than on
  // `Content`, so their starting values are asserted through it.
  private var state: CardDetailFeature.State {
    CardDetailFeature.State(card: card, queryType: queryType)
  }

  @Test func whenBuiltFromASearch_shouldNotHaveASetIcon() {
    #expect(state.setIconURL == nil)
  }

  @Test func whenBuiltFromASet_shouldTakeTheSetIcon() {
    let set = MockGameSetRequestClient.mockSets[0]
    let state = CardDetailFeature.State(
      card: card,
      queryType: .querySet(set, SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
    )

    #expect(state.setIconURL == URL(string: set.iconSvgUri))
  }

  @Test func whenBuilt_shouldStartVariantsWithTheCardItself() {
    #expect(state.variants.state.isInitial)
    #expect(state.variants.state.value?.cardDetails.count == 1)
  }

  @Test func whenBuilt_shouldStartRelatedSectionsEmpty() {
    #expect(state.relatedTokens?.state.value == nil)
    #expect(state.relatedComboPieces?.state.value == nil)
    #expect(state.relatedMeldPieces?.state.value == nil)
    #expect(state.relatedMeldResult?.state.value == nil)
  }

  /// A transforming card whose faces carry their own stats: a creature on the front and loyalty on
  /// the back. The card's own fields hold a different value, so each read shows whether it came
  /// from the face or fell back to the card.
  private var transforming: Content {
    var card = Card.mock()
    card.layout = .transform
    card.power = "1"
    card.toughness = "1"
    card.loyalty = "1"
    card.cardFaces = [
      Card.Face(manaCost: "{1}{U}", name: "Front", power: "0", toughness: "2", typeLine: "Creature"),
      Card.Face(loyalty: "5", manaCost: "", name: "Back", typeLine: "Planeswalker"),
    ]
    return Content(card: card, queryType: queryType)
  }

  /// A split card: both halves are printed side by side, so both are always described.
  private var split: Content {
    var card = Card.mock(name: "Fire // Ice")
    card.layout = .split
    card.cardFaces = [
      Card.Face(
        flavorText: "Hot.",
        manaCost: "{1}{R}",
        name: "Fire",
        oracleText: "Deal 2 damage.",
        typeLine: "Instant"
      ),
      Card.Face(
        manaCost: "{1}{U}",
        name: "Ice",
        oracleText: "Tap a permanent.\nDraw a card.",
        typeLine: "Sorcery"
      ),
    ]
    return Content(card: card, queryType: queryType)
  }

  @Test func whenCardHasNoColourIdentity_shouldReportColourless() {
    #expect(content.getColorIdentity() == ["{C}"])
  }

  @Test func whenCardHasAColourIdentity_shouldListEachColourAsASymbol() {
    var card = self.card
    card.colorIdentity = [.U, .R]

    #expect(Content(card: card, queryType: queryType).getColorIdentity() == ["{U}", "{R}"])
  }

  @Test func whenBuildingDescriptions_shouldReturnOneForASingleFacedCard() {
    #expect(content.getDescriptions().count == 1)
  }

  @Test func whenATransformingCardShowsItsBack_shouldDescribeOnlyTheBack() {
    let descriptions = transforming.getDescriptions(faceDirection: .back)

    #expect(descriptions.map(\.name) == ["Back"])
    #expect(descriptions.map(\.typeline) == ["Planeswalker"])
  }

  @Test func whenACardHasTwoColumns_shouldDescribeTheFrontThenTheBack() {
    let descriptions = split.getDescriptions()

    #expect(descriptions.map(\.name) == ["Fire", "Ice"])
    #expect(descriptions.map(\.manaCost) == [["{1}", "{R}"], ["{1}", "{U}"]])
    #expect(descriptions.map(\.typeline) == ["Instant", "Sorcery"])
    #expect(descriptions.map(\.flavorText) == ["Hot.", nil])
    #expect(descriptions.map(\.textElements.count) == [1, 2])
  }

  @Test func whenATwoColumnCardShowsItsBack_shouldStillDescribeBothFrontFirst() {
    #expect(split.getDescriptions(faceDirection: .back).map(\.name) == ["Fire", "Ice"])
  }

  @Test func whenAFaceIsOnShow_shouldReadItsStatsFromThatFace() {
    #expect(transforming.getPower(faceDirection: .front) == "0")
    #expect(transforming.getToughtness(faceDirection: .front) == "2")
    #expect(transforming.getLoyalty(faceDirection: .back) == "5")
  }

  @Test func whenTheFaceOnShowLacksAStat_shouldFallBackToTheCardsOwn() {
    #expect(transforming.getPower(faceDirection: .back) == "1")
    #expect(transforming.getToughtness(faceDirection: .back) == "1")
    #expect(transforming.getLoyalty(faceDirection: .front) == "1")
  }

  @Test func whenNoFaceIsOnShow_shouldReadTheCardsOwnStats() {
    #expect(transforming.getPower(faceDirection: nil) == "1")
    #expect(transforming.getToughtness(faceDirection: nil) == "1")
    #expect(transforming.getLoyalty(faceDirection: nil) == "1")
  }

  @Test func whenTheCardHasNoFaces_shouldReadItsOwnStatsWhicheverSideIsAskedFor() {
    var card = self.card
    card.power = "3"
    card.toughness = "4"
    card.loyalty = "5"
    let content = Content(card: card, queryType: queryType)

    #expect(content.getPower(faceDirection: .back) == "3")
    #expect(content.getToughtness(faceDirection: .back) == "4")
    #expect(content.getLoyalty(faceDirection: .back) == "5")
  }
}
