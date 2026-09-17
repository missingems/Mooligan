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

  @Test func whenInitialised_shouldHoldEveryCardInOrderAndSelectTheTappedOne() {
    let state = CardPagerFeature.State(
      cardDetails: cardDetails,
      initialSelectedCard: secondCard,
      queryType: queryType
    )

    // Every page exists from the start, so the pager never replaces its collection under the
    // page on show; each card waits for its own page to appear before it loads.
    #expect(state.selectedId == secondCard.id)
    #expect(state.cards.ids.elements == [firstCard.id, secondCard.id])
    #expect(state.cards.allSatisfy { $0.hasAppeared == false })
  }

  @Test func whenInitialSelectedCardIsNotInTheList_shouldStillHoldTheListedCards() {
    let state = CardPagerFeature.State(
      cardDetails: [CardInfo(card: secondCard)],
      initialSelectedCard: firstCard,
      queryType: queryType
    )

    #expect(state.selectedId == firstCard.id)
    #expect(state.cards.ids.elements == [secondCard.id])
  }

  @Test func whenOnePageAppears_onlyThatCardShouldLoad() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When the first page appears.
    await store.send(.cards(.element(id: firstCard.id, action: .viewAppeared)))
    await store.finish()
    await store.skipReceivedActions()

    // Then only that card has started loading; the page beside it is untouched.
    #expect(store.state.cards[id: firstCard.id]?.hasAppeared == true)
    #expect(store.state.cards[id: secondCard.id]?.hasAppeared == false)
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
