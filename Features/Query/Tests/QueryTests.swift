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

  @Test func whenPagingFailsOffline_shouldKeepTheCardsAlreadyLoaded() async {
    let loaded = CardDataSource(cards: [card], hasNextPage: true, total: 400)
    let store = TestStore(
      initialState: QueryFeature.State(mode: .data, queryType: .querySet(set, searchQuery))
    ) {
      QueryFeature()
    } withDependencies: {
      $0.cardQueryRequestClient = MockCardQueryRequestClient(
        expectedResponse: ObjectList(data: [.mock()]),
        failingFromPage: 2
      )
    }

    await store.send(.updateCards(loaded, searchQuery, .data)) { state in
      state.dataSource = loaded
      state.mode = .data
    }

    await store.send(.loadMoreCardsIfNeeded(displayingIndex: 0))
    await store.receive(.pagingFailed) { state in
      state.dataSource.hasNextPage = false
    }

    #expect(store.state.dataSource.cardDetails.count == 1)
    #expect(store.state.query.page == 1)
  }

  @Test func whenPagingSucceeds_shouldAdvanceTheQueryOnlyOnceResultsArrive() async {
    let loaded = CardDataSource(cards: [card], hasNextPage: true, total: 400)
    let store = makeStore(mode: .data)
    var pageTwo = searchQuery
    pageTwo.page = 2

    await store.send(.updateCards(loaded, searchQuery, .data)) { state in
      state.dataSource = loaded
      state.mode = .data
    }

    await store.send(.loadMoreCardsIfNeeded(displayingIndex: 0))

    var expected = loaded
    expected.append(cards: [.mock()])
    expected.hasNextPage = false

    await store.receive(.updateCards(expected, pageTwo, .data)) { state in
      state.dataSource = expected
      state.query = pageTwo
      state.mode = .data
    }
  }

  @Test func whenPulledToRefresh_shouldReloadFromTheFirstPage() async {
    let store = makeStore(mode: .data)
    let expected = CardDataSource(cards: [card], hasNextPage: false, total: 0)

    await store.send(.refresh)

    await store.receive(.updateCards(expected, searchQuery.first(), .data)) { state in
      state.dataSource = expected
      state.mode = .data
    }
  }

  @Test func whenRefreshingAfterPaging_shouldResetTheQueryToPageOne() async {
    var paged = searchQuery
    paged.page = 4
    let store = TestStore(
      initialState: QueryFeature.State(mode: .data, queryType: .querySet(set, paged))
    ) {
      QueryFeature()
    } withDependencies: {
      $0.cardQueryRequestClient = MockCardQueryRequestClient(
        expectedResponse: ObjectList(data: [.mock()])
      )
    }
    let expected = CardDataSource(cards: [card], hasNextPage: false, total: 0)

    await store.send(.refresh)

    await store.receive(.updateCards(expected, paged.first(), .data)) { state in
      state.dataSource = expected
      state.query = paged.first()
      state.mode = .data
    }
  }

  @Test func whenViewAppearedWithAPlaceholder_shouldQueryCards() async {
    let store = makeStore()
    let expected = CardDataSource(cards: [card], hasNextPage: false, total: 0)

    await store.send(.viewAppeared)

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

    await store.send(.performSearch)

    await store.receive(.updateCards(store.state.dataSource, searchQuery, .loading)) { state in
      state.mode = .loading
    }

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

    await store.send(.updateCards(firstPage, searchQuery, .data)) { state in
      state.dataSource = firstPage
      state.mode = .data
    }

    await store.send(.loadMoreCardsIfNeeded(displayingIndex: 0))

    await store.receive(\.updateCards)
    await store.finish()

    #expect(store.state.dataSource.cardDetails.count == 2)
  }

  @Test func whenShowingLastCardWithoutMorePages_shouldNotLoadMore() async {
    let store = makeStore(mode: .data)
    let onePage = CardDataSource(cards: [card], hasNextPage: false, total: 1)

    await store.send(.updateCards(onePage, searchQuery, .data)) { state in
      state.dataSource = onePage
      state.mode = .data
    }

    await store.send(.loadMoreCardsIfNeeded(displayingIndex: 0))
  }

  @Test func whenShowingACardBeforeTheLast_shouldNotLoadMore() async {
    let store = makeStore(mode: .data)
    let pages = CardDataSource(cards: [card, .mock(id: UUID())], hasNextPage: true, total: 5)

    await store.send(.updateCards(pages, searchQuery, .data)) { state in
      state.dataSource = pages
      state.mode = .data
    }

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

    await store.send(.retry) { state in
      state.mode = .error(placeholder: nil, isRetrying: true, isInitial: false)
    }

    await store.receive(.updateCards(expected, searchQuery, .data)) { state in
      state.dataSource = expected
      state.mode = .data
    }
  }

  @Test func whenRetryingOutsideAnError_shouldReturnToPlaceholder() async {
    let store = makeStore(mode: .data)
    store.exhaustivity = .off

    await store.send(.retry) { state in
      state.mode = .placeholder
    }

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
