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

  @Test func whenDismissTapped_shouldNotChangeState() async {
    let store = makeStore()

    await store.send(.dismissTapped)
  }

  @Test func whenCardHasNoRulings_shouldDescribeTheEmptyState() {
    let state = RulingFeature.State(card: card, title: "Rulings")

    #expect(state.emptyStateTitle == "No Results for \"\(card.name)\"")
  }
}
