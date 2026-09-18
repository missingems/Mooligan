@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct RulingFeatureTests {
  private let card = Card.mock()

  private func makeStore() -> TestStoreOf<RulingFeature> {
    TestStore(initialState: RulingFeature.State(card: card, title: "Rulings")) {
      RulingFeature()
    }
  }

  @Test func whenInitialised_shouldStartLoading() {
    let state = RulingFeature.State(card: card, title: "Rulings")

    #expect(state.mode == .loading)
    #expect(state.title == "Rulings")
  }

  @Test func whenFetchingRulings_shouldLoadThem() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When
    await store.send(.fetchRulings)
    await store.finish()
    await store.skipReceivedActions()

    // Then. `MagicCardRuling` mints a new id on init and compares by it, so the
    // rulings are checked by content rather than by value.
    guard case let .loaded(rulings) = store.state.mode else {
      Issue.record("Expected the rulings to be loaded.")
      return
    }

    #expect(rulings.count == 1)
    #expect(rulings.first?.displayDate == "12-10-1992")
    #expect(
      rulings.first?.description == [
        [
          .text("italic", isItalic: true, isKeyword: false),
          .text("normal", isItalic: false, isKeyword: false),
          .text("keyword", isItalic: false, isKeyword: true),
        ]
      ]
    )
  }

  @Test func whenCardHasNoRulings_shouldDescribeTheEmptyState() {
    let state = RulingFeature.State(card: card, title: "Rulings")

    #expect(state.emptyStateTitle == "No Results for \"\(card.name)\"")
  }

  @Test func whenCardHasAGathererPage_shouldPointTheEmptyStateToIt() {
    var card = self.card
    card.relatedUris = [
      "gatherer": "https://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=600",
      "edhrec": "https://edhrec.com/route/?cc=Card",
    ]

    let state = RulingFeature.State(card: card, title: "Rulings")

    #expect(
      state.emptyStateDescription
        == "Look up https://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=600 for more information."
    )
  }

  @Test func whenCardHasNoGathererPage_shouldOfferNoEmptyStateDescription() {
    // Scryfall only links Gatherer for a card with a multiverse id; the other links do not count.
    var card = self.card
    card.relatedUris = ["edhrec": "https://edhrec.com/route/?cc=Card"]

    let state = RulingFeature.State(card: card, title: "Rulings")

    #expect(state.emptyStateDescription == nil)
  }
}
