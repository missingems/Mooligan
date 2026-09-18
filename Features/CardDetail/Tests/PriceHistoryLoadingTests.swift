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
    clock: TestClock<Duration>,
    sets: any GameSetRequestClient = MockGameSetRequestClient()
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
      $0.continuousClock = clock
      $0.gameSetRequestClient = sets
    }
  }

  @Test func aNewCardShouldStartInTheLoadingDisplay() {
    let state = CardDetailFeature.State(
      card: card,
      queryType: .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
    )

    #expect(state.priceHistory == PriceHistoryDisplay.loading(card: card, labels: labels))
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

  /// An empty feed is not an error: there is nothing to retry, and the card's Scryfall prices
  /// still draw as a flat week.
  @Test func whenTheFeedDoesNotKnowTheCard_shouldFallBackToScryfallWithoutRetrying() async {
    let clock = TestClock()
    let client = CountingEmptyClient()
    let store = makeStore(client: client, clock: clock)
    let fallback = PriceHistorySection.makeState(card: card, history: nil)

    await store.send(.fetchPriceHistory(card: card))
    await store.receive(\.updatePriceHistory) { state in
      state.priceHistory = PriceHistoryDisplay.make(card: card, state: fallback, labels: labels)
    }

    #expect(await client.calls == 1)
    #expect(store.state.priceHistory.status == .loaded)
  }

  /// Set releases only mark the chart, so failing to fetch them must not cost the reader the chart.
  @Test func whenTheSetsCannotBeFetched_shouldStillLoadTheChartWithNothingMarked() async throws {
    let sets = FailingSetsClient()
    // A chart only marks releases inside the days it draws, and the store only keeps the last 400
    // days of them. Drawn over 420 days, this chart would show any release the store could hold, so
    // an unmarked chart means the failed request left no releases at all.
    let feed = MockPriceHistoryClient(dayCount: 420)
    let histories = try await feed.histories(for: card, requests: PriceHistorySection.priceRequests)
    let unmarked = PriceHistorySection.makeState(
      card: card,
      history: histories[PriceHistorySection.chartRequest],
      buylistQuote: PriceHistorySection.buylistQuote(from: histories),
      releases: []
    )
    guard case let .data(section) = unmarked else {
      Issue.record("Expected the mock feed to draw a chart.")
      return
    }
    #expect(section.dateRange.lowerBound < Date().addingTimeInterval(-400 * 86_400))

    // The releases load once and serve every card, so a card asks for the sets only while nothing
    // holds them. Other tests' cards load them too, in parallel with this one; when one of them
    // gets in between the reset and this card's load, clear them and try again.
    for _ in 1...10 {
      let store = makeStore(client: feed, clock: TestClock(), sets: sets)

      // Given the releases have not loaded yet.
      await SetReleaseMarkerStore.shared.reset()

      // When
      await store.send(.fetchPriceHistory(card: card))

      // Then the chart loads without a release on it.
      await store.receive(\.updatePriceHistory) { state in
        state.priceHistory = PriceHistoryDisplay.make(card: card, state: unmarked, labels: labels)
      }
      if sets.calls.value > 0 { break }
    }

    // And it was this card's failed request for the sets that left the chart unmarked.
    #expect(sets.calls.value == 1)
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
}
