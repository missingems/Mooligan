@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct CardPagerFeatureTests {
  private let firstCard = Card.mock(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
  private let secondCard = Card.mock(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002"))

  private var queryType: QueryType {
    .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
  }

  private var cardDetails: [CardInfo] {
    [CardInfo(card: firstCard), CardInfo(card: secondCard)]
  }

  private func makeStore() -> TestStoreOf<CardPagerFeature> {
    TestStore(
      initialState: CardPagerFeature.State(
        cardDetails: cardDetails,
        initialSelectedCard: firstCard,
        queryType: queryType
      )
    ) {
      CardPagerFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }
  }

  @Test func whenInitialised_shouldOnlyHoldTheSelectedCard() {
    let state = CardPagerFeature.State(
      cardDetails: cardDetails,
      initialSelectedCard: firstCard,
      queryType: queryType
    )

    #expect(state.selectedId == firstCard.id)
    #expect(state.cards.count == 1)
    #expect(state.cards[id: firstCard.id] != nil)
  }

  @Test func whenInitialSelectedCardIsNotInTheList_shouldHoldNoCards() {
    let state = CardPagerFeature.State(
      cardDetails: [CardInfo(card: secondCard)],
      initialSelectedCard: firstCard,
      queryType: queryType
    )

    #expect(state.cards.isEmpty)
  }

  @Test func whenViewAppeared_shouldHydrateRemainingCardsWithoutLoadingThem() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When
    await store.send(.viewAppeared)
    await store.receive(\.setRemainingCards)

    // Then the rest of the set is hydrated, and each card waits for its own page to load it.
    #expect(store.state.cards.count == 2)
    #expect(store.state.cards.allSatisfy { $0.hasAppeared == false })
  }

  @Test func whenSettingRemainingCards_shouldPreserveAlreadyLoadedCards() async {
    let store = makeStore()
    store.exhaustivity = .off

    // Given the selected card has already loaded.
    await store.send(.cards(.element(id: firstCard.id, action: .viewAppeared)))
    await store.finish()
    await store.skipReceivedActions()

    // When the full set arrives.
    await store.send(.viewAppeared)
    await store.receive(\.setRemainingCards)

    // Then the loaded card keeps its state rather than being replaced by a fresh one.
    #expect(store.state.cards.count == 2)
    #expect(store.state.cards[id: firstCard.id]?.hasAppeared == true)
    #expect(store.state.cards[id: secondCard.id]?.hasAppeared == false)
  }

  @Test func whenAllCardsAreLoaded_shouldNotHydrateAgain() async {
    let store = makeStore()
    store.exhaustivity = .off

    // Given
    await store.send(.viewAppeared)
    await store.receive(\.setRemainingCards)

    // When / Then no second hydration runs.
    await store.send(.viewAppeared)
    await store.finish()

    #expect(store.state.cards.count == 2)
  }

  @Test func whenViewRulingsTapped_shouldPresentRulings() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When
    await store.send(.cards(.element(id: firstCard.id, action: .viewRulingsTapped))) { state in
      state.showRulings = RulingFeature.State(card: self.firstCard, title: "Rulings")
    }

    await store.finish()
  }
}
