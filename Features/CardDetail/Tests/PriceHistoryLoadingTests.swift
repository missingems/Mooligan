@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct PriceHistoryLoadingTests {
  private let card = Card.mock()
  private let labels = PriceHistoryLabels()

  private func makeStore(
    status: PriceHistoryState = .loading,
    client: any PriceHistoryClient,
    purchaseLinks: any PurchaseLinksClient = MockPurchaseLinksClient(),
    clock: TestClock<Duration>
  ) -> TestStoreOf<CardDetailFeature> {
    var state = CardDetailFeature.State(
      card: card,
      queryType: .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
    )
    state.priceHistory = PriceHistoryDisplay.make(card: card, state: status, labels: labels)

    return TestStore(initialState: state) {
      CardDetailFeature()
    } withDependencies: {
      $0.priceHistoryClient = client
      $0.purchaseLinksClient = purchaseLinks
      $0.continuousClock = clock
    }
  }

  @Test func aNewCardShouldStartInTheLoadingDisplay() {
    let state = CardDetailFeature.State(
      card: card,
      queryType: .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
    )

    #expect(state.priceHistory == PriceHistoryDisplay.loading(card: card, labels: labels))
    #expect(state.purchaseDropdown == .loading)
  }

  @Test func whenTheCardAppears_shouldLoadPriceHistoryWithItsSections() async {
    let clock = TestClock()
    let client = CountingMockClient()
    let store = makeStore(client: client, clock: clock)
    store.exhaustivity = .off

    await store.send(.viewAppeared)
    await store.receive(\.updatePriceHistory)

    #expect(await client.calls == 1)
    #expect(store.state.priceHistory.status == .loaded)
  }

  @Test func whenTheFirstAttemptFails_shouldRetryAutomaticallyAndLoad() async {
    let clock = TestClock()
    let store = makeStore(client: FlakyPriceHistoryClient(failuresPerCard: 1), clock: clock)
    store.exhaustivity = .off

    await store.send(.fetchPriceHistory(card: card))
    await clock.advance(by: PriceHistoryLoader.retryDelays[0])
    await store.receive(\.updatePriceHistory)

    #expect(store.state.priceHistory.status == .loaded)
    #expect(store.state.priceHistory.hasChart)
  }

  @Test func whenEveryAttemptFails_shouldEndInTheFailedState() async {
    let clock = TestClock()
    let store = makeStore(client: FlakyPriceHistoryClient(failuresPerCard: 10), clock: clock)
    store.exhaustivity = .off

    await store.send(.fetchPriceHistory(card: card))
    for delay in PriceHistoryLoader.retryDelays {
      await clock.advance(by: delay)
    }
    await store.receive(\.updatePriceHistory)

    #expect(store.state.priceHistory.status == .failed)
  }

  @Test func whenARequestHangs_shouldTimeOutAndRetry() async {
    let clock = TestClock()
    let store = makeStore(client: HangingOnceClient(), clock: clock)
    store.exhaustivity = .off

    await store.send(.fetchPriceHistory(card: card))
    await clock.advance(by: PriceHistoryLoader.attemptTimeout)
    await clock.advance(by: PriceHistoryLoader.retryDelays[0])
    await store.receive(\.updatePriceHistory)

    #expect(store.state.priceHistory.status == .loaded)
  }

  @Test func whenTheFeedDoesNotKnowTheCard_shouldShowNoDataWithoutRetrying() async {
    let clock = TestClock()
    let client = CountingEmptyClient()
    let store = makeStore(client: client, clock: clock)

    await store.send(.fetchPriceHistory(card: card))
    await store.receive(\.updatePriceHistory) { state in
      state.priceHistory = PriceHistoryDisplay.make(card: card, state: .unavailable, labels: labels)
    }

    #expect(await client.calls == 1)
  }

  @Test func whenRetryIsTapped_shouldReloadFromTheLoadingDisplay() async {
    let clock = TestClock()
    let store = makeStore(status: .failed, client: MockPriceHistoryClient(), clock: clock)
    store.exhaustivity = .off

    await store.send(.retryPriceHistoryTapped)
    await store.receive(\.fetchPriceHistory) { state in
      state.priceHistory = PriceHistoryDisplay.loading(card: card, labels: labels)
    }
    await store.receive(\.updatePriceHistory)

    #expect(store.state.priceHistory.status == .loaded)
  }

  @Test func whenPurchaseLinksAreRequested_shouldLoadThemOnceAndPriceThem() async {
    let store = makeStore(client: MockPriceHistoryClient(), clock: TestClock())
    let links = (try? await MockPurchaseLinksClient().purchaseLinks(for: card)) ?? []

    await store.send(.purchaseLinksRequested) { state in
      state.purchaseLinks = .loading
    }
    await store.receive(\.updatePurchaseLinks) { state in
      state.purchaseLinks = .loaded(links)
      state.purchaseDropdown = .loaded(
        PurchaseVendorGroup.make(links: links, quotes: [:], scryfallPrices: card.prices)
      )
    }

    await store.send(.purchaseLinksRequested)
  }

  @Test func whenPurchaseLinksFail_shouldAllowAnotherAttempt() async {
    let links = FailingOncePurchaseLinksClient()
    let store = makeStore(client: MockPriceHistoryClient(), purchaseLinks: links, clock: TestClock())
    let loaded = PurchaseLinksMapper.makeLinks(from: FailingOncePurchaseLinksClient.urls)

    await store.send(.purchaseLinksRequested) { state in
      state.purchaseLinks = .loading
    }
    await store.receive(\.updatePurchaseLinks) { state in
      state.purchaseLinks = .failed
      state.purchaseDropdown = .failed
    }

    await store.send(.purchaseLinksRequested) { state in
      state.purchaseLinks = .loading
      state.purchaseDropdown = .loading
    }
    await store.receive(\.updatePurchaseLinks) { state in
      state.purchaseLinks = .loaded(loaded)
      state.purchaseDropdown = .loaded(
        PurchaseVendorGroup.make(links: loaded, quotes: [:], scryfallPrices: card.prices)
      )
    }
  }

  @Test func loadedPricesShouldRepriceTheOpenDropdown() async {
    let clock = TestClock()
    let store = makeStore(client: MockPriceHistoryClient(), clock: clock)
    store.exhaustivity = .off

    await store.send(.purchaseLinksRequested)
    await store.receive(\.updatePurchaseLinks)
    await store.send(.fetchPriceHistory(card: card))
    await store.receive(\.updatePriceHistory)

    guard case let .loaded(groups) = store.state.purchaseDropdown else {
      Issue.record("expected loaded links")
      return
    }
    let tcgplayer = groups.first { $0.provider == .tcgplayer }
    #expect(tcgplayer?.offers.allSatisfy { $0.priceText != nil } == true)
  }
}
