@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct PullOddsLoadingTests {
  private let card = Card.mock()

  private let odds = CardPullOdds(products: [
    ProductPullOdds(
      id: "fdn/play",
      name: "Play Booster",
      setName: "Foundations",
      chance: 1.0 / 168,
      foilChance: 1.0 / 2_100,
      nonFoilChance: 1.0 / 182
    ),
  ])

  private func makeStore(
    queryType: QueryType = .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto)),
    source: PullOddsSourceSpy,
    client: any MagicCardDetailRequestClient = VariantsPageClient(variants: nil)
  ) -> TestStoreOf<CardDetailFeature> {
    let store = TestStore(initialState: CardDetailFeature.State(card: card, queryType: queryType)) {
      CardDetailFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.cardDetailRequestClient = client
      $0.priceHistoryClient = MockPriceHistoryClient()
      $0.cardPullOddsSource = source
    }
    // The sections and price history load alongside; other suites cover them.
    store.exhaustivity = .off
    return store
  }

  @Test func aNewCard_shouldStartWithItsOddsLoading() {
    let state = CardDetailFeature.State(card: card, queryType: .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto)))

    #expect(state.pullOdds == .loading)
    #expect(state.pullOdds.odds == nil)
  }

  @Test func whenTheCardAppears_shouldLoadItsOddsWithItsOtherInformation() async {
    let store = makeStore(source: PullOddsSourceSpy(odds: odds))

    await store.send(.viewAppeared)

    await store.receive(.updatePullOdds(odds)) { state in
      state.pullOdds = .loaded(odds!)
    }
    await store.finish()
  }

  @Test func whenThereAreNoOdds_shouldLeaveTheTileOut() async {
    let store = makeStore(source: PullOddsSourceSpy(odds: nil))

    await store.send(.viewAppeared)

    await store.receive(.updatePullOdds(nil)) { state in
      state.pullOdds = .unavailable
    }
    await store.finish()
  }

  @Test func whenTheOddsHaveSettled_appearingAgainShouldNotAskAgain() async {
    let source = PullOddsSourceSpy(odds: nil)
    let store = makeStore(source: source)
    await store.send(.viewAppeared)
    await store.finish()
    await store.skipReceivedActions()

    await store.send(.viewAppeared)
    await store.finish()

    #expect(source.parentSetCodes.value.count == 1)
  }

  @Test func aCardInACommanderSet_shouldBeAskedForWithItsParentSet() async {
    var commander = MockGameSetRequestClient.mockSets[0]
    commander.parentSetCode = "blb"
    let source = PullOddsSourceSpy(odds: odds)
    let store = makeStore(source: source, client: VariantsPageClient(variants: nil, set: commander))

    await store.send(.viewAppeared)
    await store.finish()

    #expect(source.parentSetCodes.value == ["blb"])
  }

  @Test func browsingTheCardsOwnSet_shouldTakeTheParentFromIt() async {
    var browsed = MockGameSetRequestClient.mockSets[0]
    browsed.code = card.set
    browsed.parentSetCode = "blb"
    let source = PullOddsSourceSpy(odds: odds)
    // A client that cannot find the set, so the parent can only have come from the browsed set.
    let store = makeStore(
      queryType: .querySet(browsed, SearchQuery(page: 1, sortMode: .name, sortDirection: .auto)),
      source: source
    )

    await store.send(.viewAppeared)
    await store.finish()

    #expect(source.parentSetCodes.value == ["blb"])
  }

  @Test func whenTheSetCannotBeFound_shouldStillAskWithoutAParent() async {
    let source = PullOddsSourceSpy(odds: odds)
    let store = makeStore(source: source)

    await store.send(.viewAppeared)
    await store.finish()

    #expect(source.parentSetCodes.value == [nil])
  }
}
