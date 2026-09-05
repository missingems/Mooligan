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

  @Test func whenViewAppeared_shouldLoadSelectedCard_thenHydrateRemainingCards() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When
    await store.send(.viewAppeared)

    // Should load the card the user tapped into, since no scroll settle will fire for it.
    await store.receive(.currentCardSettled(id: firstCard.id))

    await store.finish()
    await store.skipReceivedActions()

    // Then the rest of the set is hydrated, and only the settled card has loaded.
    #expect(store.state.cards.count == 2)
    #expect(store.state.cards[id: firstCard.id]?.hasAppeared == true)
    #expect(store.state.cards[id: secondCard.id]?.hasAppeared == false)
  }

  @Test func whenSettlingOnACard_shouldFetchThatCardsAdditionalInformation() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When
    await store.send(.currentCardSettled(id: firstCard.id))

    // Then only that card loads.
    await store.receive(
      .cards(
        .element(
          id: firstCard.id,
          action: .viewAppeared(initialAction: .fetchAdditionalInformation(card: firstCard))
        )
      )
    )

    await store.finish()
  }

  @Test func whenSettlingOnNoCard_shouldDoNothing() async {
    let store = makeStore()

    await store.send(.currentCardSettled(id: nil))
  }

  @Test func whenSettlingOnAnUnknownCard_shouldDoNothing() async {
    let store = makeStore()

    await store.send(.currentCardSettled(id: UUID()))
  }

  @Test func whenSettlingOnTheSameCardTwice_shouldOnlyFetchOnce() async {
    let store = makeStore()
    store.exhaustivity = .off

    // Given
    await store.send(.currentCardSettled(id: firstCard.id))
    await store.finish()
    await store.skipReceivedActions()

    #expect(store.state.cards[id: firstCard.id]?.hasAppeared == true)

    // When the user swipes away and back.
    await store.send(.currentCardSettled(id: firstCard.id))
    await store.receive(\.cards)
    await store.finish()

    // Then the card guards against fetching its sections again.
    #expect(store.state.cards[id: firstCard.id]?.hasAppeared == true)
  }

  @Test func whenSettingRemainingCards_shouldPreserveAlreadyLoadedCards() async {
    let store = makeStore()
    store.exhaustivity = .off

    // Given the selected card has already loaded.
    await store.send(.currentCardSettled(id: firstCard.id))
    await store.finish()
    await store.skipReceivedActions()

    // When the full set arrives.
    await store.send(.viewAppeared)
    await store.finish()
    await store.skipReceivedActions()

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
    await store.finish()
    await store.skipReceivedActions()

    // When
    await store.send(.viewAppeared)

    // Then only the settle is sent, no second hydration.
    await store.receive(\.currentCardSettled)
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
