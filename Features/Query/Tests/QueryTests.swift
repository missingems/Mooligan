@testable import Query
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct QueryFeatureTests {
  private let card = Card.mock()

  private var set: MTGSet {
    MockGameSetRequestClient.mockSets[0]
  }

  private var searchQuery: SearchQuery {
    SearchQuery(page: 1, sortMode: .name, sortDirection: .auto)
  }

  private func makeStore(
    mode: QueryFeature.State.Mode = .placeholder,
    response: ObjectList<Card> = ObjectList(data: [.mock()])
  ) -> TestStoreOf<QueryFeature> {
    TestStore(
      initialState: QueryFeature.State(mode: mode, queryType: .querySet(set, searchQuery))
    ) {
      QueryFeature()
    } withDependencies: {
      $0.cardQueryRequestClient = MockCardQueryRequestClient(expectedResponse: response)
    }
  }

  @Test func whenInitialisedForASet_shouldTakeItsTitleAndIdentity() {
    let state = QueryFeature.State(mode: .placeholder, queryType: .querySet(set, searchQuery))

    #expect(state.title == set.name)
    #expect(state.id == set.id)
    #expect(state.dataSource.cardDetails.isEmpty)
    #expect(state.isShowingInfo == false)
    #expect(state.isSearchExpanded == false)
  }

  @Test func whenInitialisedForASearch_shouldUseTheSearchTitle() {
    let state = QueryFeature.State(mode: .placeholder, queryType: .search(searchQuery))

    #expect(state.title == "Search")
  }

  @Test func whenViewAppearedWithAPlaceholder_shouldQueryCards() async {
    let store = makeStore()
    let expected = CardDataSource(cards: [card], hasNextPage: false, total: 0)

    // When
    await store.send(.viewAppeared)

    // Then
    await store.receive(.updateCards(expected, searchQuery, .data)) { state in
      state.dataSource = expected
      state.mode = .data
    }
  }

  @Test func whenViewAppearedWithData_shouldNotQueryAgain() async {
    let store = makeStore(mode: .data)

    await store.send(.viewAppeared)
  }

  @Test func whenPerformingSearch_shouldShowLoading_thenData_thenScrollToTop() async {
    let store = makeStore(mode: .data)
    let expected = CardDataSource(cards: [card], hasNextPage: false, total: 0)

    // When
    await store.send(.performSearch)

    // Should show loading first, keeping the existing data source.
    await store.receive(.updateCards(store.state.dataSource, searchQuery, .loading)) { state in
      state.mode = .loading
    }

    // Then the results arrive.
    await store.receive(.updateCards(expected, searchQuery, .data)) { state in
      state.dataSource = expected
      state.mode = .data
    }

    await store.receive(.scrollToTop) { state in
      state.scrollPosition.scrollTo(edge: .top)
    }
  }

  @Test func whenUpdatingWithNilCards_shouldLeaveStateUntouched() async {
    let store = makeStore(mode: .data)

    await store.send(.updateCards(nil, searchQuery, .loading))
  }

  @Test func whenSelectingShowInfo_shouldFlagIt() async {
    let store = makeStore()

    await store.send(.didSelectShowInfo) { state in
      state.isShowingInfo = true
    }
  }

  @Test func whenSelectingCard_shouldNotChangeState() async {
    let store = makeStore()

    await store.send(.didSelectCard(card, .querySet(set, searchQuery)))
  }

  @Test func whenShowingLastCardWithMorePages_shouldLoadMore() async {
    let store = makeStore(mode: .data)
    store.exhaustivity = .off
    let firstPage = CardDataSource(cards: [card], hasNextPage: true, total: 2)

    // Given
    await store.send(.updateCards(firstPage, searchQuery, .data)) { state in
      state.dataSource = firstPage
      state.mode = .data
    }

    // When
    await store.send(.loadMoreCardsIfNeeded(displayingIndex: 0))

    // Then the next page is appended.
    await store.receive(\.updateCards)
    await store.finish()

    #expect(store.state.dataSource.cardDetails.count == 2)
  }

  @Test func whenShowingLastCardWithoutMorePages_shouldNotLoadMore() async {
    let store = makeStore(mode: .data)
    let onePage = CardDataSource(cards: [card], hasNextPage: false, total: 1)

    // Given
    await store.send(.updateCards(onePage, searchQuery, .data)) { state in
      state.dataSource = onePage
      state.mode = .data
    }

    // When / Then
    await store.send(.loadMoreCardsIfNeeded(displayingIndex: 0))
  }

  @Test func whenShowingACardBeforeTheLast_shouldNotLoadMore() async {
    let store = makeStore(mode: .data)
    let pages = CardDataSource(cards: [card, .mock(id: UUID())], hasNextPage: true, total: 5)

    // Given
    await store.send(.updateCards(pages, searchQuery, .data)) { state in
      state.dataSource = pages
      state.mode = .data
    }

    // When / Then
    await store.send(.loadMoreCardsIfNeeded(displayingIndex: 0))
  }

  @Test func whenTogglingAnUnknownCardFace_shouldDoNothing() async {
    let store = makeStore(mode: .data)

    await store.send(.cardFaceToggled(id: UUID()))
  }

  @Test func whenPlaceholderCardUpdates_shouldEnterErrorMode() async {
    let store = makeStore(mode: .data)

    await store.send(.updatePlaceholderCard(card, isInitial: true, noInternet: false)) { state in
      state.mode = .error(placeholder: self.card, isRetrying: false, isInitial: true, noInternet: false)
      state.dataSource = CardDataSource(cards: [], hasNextPage: false, total: 0)
    }
  }

  @Test func whenRetryingFromAnError_shouldMarkAsRetrying_thenLoadData() async {
    let store = makeStore(mode: .error(placeholder: nil, isRetrying: false, isInitial: false))
    let expected = CardDataSource(cards: [card], hasNextPage: false, total: 0)

    // When
    await store.send(.retry) { state in
      state.mode = .error(placeholder: nil, isRetrying: true, isInitial: false)
    }

    // Then
    await store.receive(.updateCards(expected, searchQuery, .data)) { state in
      state.dataSource = expected
      state.mode = .data
    }
  }

  @Test func whenRetryingOutsideAnError_shouldReturnToPlaceholder() async {
    let store = makeStore(mode: .data)
    store.exhaustivity = .off

    // When
    await store.send(.retry) { state in
      state.mode = .placeholder
    }

    // Then it re-runs the initial appearance.
    await store.receive(\.viewAppeared)
    await store.finish()
  }
}

@MainActor struct QueryFeatureModeTests {
  @Test func whenPlaceholder_shouldHideTopBarAndNotScroll() {
    let mode = QueryFeature.State.Mode.placeholder

    #expect(mode.isPlaceholder)
    #expect(mode.shouldHideTopBar)
    #expect(mode.isScrollable == false)
    #expect(mode.isLoading)
    #expect(mode.hasError == false)
  }

  @Test func whenData_shouldBeScrollable() {
    let mode = QueryFeature.State.Mode.data

    #expect(mode.isPlaceholder == false)
    #expect(mode.isScrollable)
    #expect(mode.isLoading == false)
    #expect(mode.hasError == false)
  }

  @Test func whenLoading_shouldNotBeScrollable() {
    let mode = QueryFeature.State.Mode.loading

    #expect(mode.isScrollable == false)
    #expect(mode.isLoading)
    #expect(mode.hasError == false)
  }

  @Test func whenInitialError_shouldHideTopBar() {
    let mode = QueryFeature.State.Mode.error(placeholder: nil, isRetrying: false, isInitial: true)

    #expect(mode.hasError)
    #expect(mode.isInitialError)
    #expect(mode.shouldHideTopBar)
    #expect(mode.isScrollable == false)
  }

  @Test func whenRetryingAnError_shouldReportLoading() {
    let mode = QueryFeature.State.Mode.error(placeholder: nil, isRetrying: true, isInitial: false)

    #expect(mode.isLoading)
    #expect(mode.isInitialError == false)
    #expect(mode.shouldHideTopBar == false)
  }
}
