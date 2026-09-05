@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct CardDetailFeatureTests {
  private let card = Card.mock()

  private var queryType: QueryType {
    .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
  }

  private func makeStore() -> TestStoreOf<CardDetailFeature> {
    TestStore(
      initialState: CardDetailFeature.State(card: card, queryType: queryType)
    ) {
      CardDetailFeature()
    }
  }

  private var emptyDataSource: CardDataSource {
    CardDataSource(cards: [], hasNextPage: false, total: 0)
  }

  @Test func whenInitialised_shouldNotHaveAppeared() {
    let state = CardDetailFeature.State(card: card, queryType: queryType)

    #expect(state.hasAppeared == false)
    #expect(state.id == card.id)
    #expect(state.content.card == card)
  }

  @Test func whenViewAppeared_shouldSendInitialAction() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When
    await store.send(.viewAppeared(initialAction: .fetchSetIcon(card: card)))

    // Should
    await store.receive(.fetchSetIcon(card: card))

    // Then
    #expect(store.state.hasAppeared == false)

    await store.finish()
  }

  @Test func whenViewAppearedTwice_shouldOnlySendInitialActionOnce() async {
    let store = makeStore()
    store.exhaustivity = .off

    // Given
    await store.send(.fetchAdditionalInformation(card: card)) { state in
      state.hasAppeared = true
    }

    // When
    await store.send(.viewAppeared(initialAction: .fetchSetIcon(card: card)))

    // Then no initial action is forwarded, because the card already appeared.
    await store.finish()
  }

  @Test func whenFetchingAdditionalInformation_shouldMarkAsAppeared_thenFanOutFetches() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When
    await store.send(.fetchAdditionalInformation(card: card)) { state in
      state.hasAppeared = true
    }

    // Should
    await store.receive(.fetchSetIcon(card: card))
    await store.receive(.fetchVariants(card: card, page: 1))
    await store.receive(.fetchRelatedTokens(card: card))
    await store.receive(.fetchRelatedComboPieces(card: card))
    await store.receive(.fetchRelatedMeldPieces(card: card))
    await store.receive(.fetchRelatedMeldResult(card: card))

    await store.finish()
  }

  @Test func whenQueryTypeIsSet_shouldNotRefetchSetIcon() async {
    let set = MockGameSetRequestClient.mockSets[0]
    let store = TestStore(
      initialState: CardDetailFeature.State(
        card: card,
        queryType: .querySet(set, SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
      )
    ) {
      CardDetailFeature()
    }
    store.exhaustivity = .off

    // Given the set icon is already known from the query type.
    #expect(store.state.content.setIconURL == URL(string: set.iconSvgUri))

    // When
    await store.send(.fetchAdditionalInformation(card: card)) { state in
      state.hasAppeared = true
    }

    // Should skip the set icon fetch and go straight to the rest.
    await store.receive(.fetchVariants(card: card, page: 1))

    await store.finish()
  }

  @Test func whenUpdatingSetIconURL_shouldStoreURL() async {
    let store = makeStore()
    let url = URL(string: "https://mooligan.com/icon.svg")

    await store.send(.updateSetIconURL(url)) { state in
      state.content.setIconURL = url
    }
  }

  @Test func whenUpdatingSetIconURLWithNil_shouldKeepExistingURL() async {
    let store = makeStore()
    let url = URL(string: "https://mooligan.com/icon.svg")

    // Given
    await store.send(.updateSetIconURL(url)) { state in
      state.content.setIconURL = url
    }

    // When / Then the nil is ignored rather than clearing the icon.
    await store.send(.updateSetIconURL(nil))
  }

  @Test func whenUpdatingVariants_shouldStoreDataSourceAndPage() async {
    let store = makeStore()
    let dataSource = CardDataSource(cards: [.mock(id: nil)], hasNextPage: true, total: 1)

    await store.send(.updateVariants(dataSource, page: 2)) { state in
      state.content.variants = state.content.variants.updating(page: 2, state: .data(dataSource))
    }
  }

  @Test func whenUpdatingRelatedTokens_shouldStoreDataSource() async {
    let store = makeStore()
    let dataSource = CardDataSource(cards: [.mock(id: nil)], hasNextPage: false, total: 1)

    await store.send(.updateRelatedTokens(dataSource)) { state in
      state.content.relatedTokens = state.content.relatedTokens?.updating(page: 1, state: .data(dataSource))
    }
  }

  @Test func whenUpdatingComboPieces_shouldStoreDataSource() async {
    let store = makeStore()
    let dataSource = CardDataSource(cards: [.mock(id: nil)], hasNextPage: false, total: 1)

    await store.send(.updateComboPieces(dataSource)) { state in
      state.content.relatedComboPieces = state.content.relatedComboPieces?.updating(page: 1, state: .data(dataSource))
    }
  }

  @Test func whenUpdatingMeldPieces_shouldStoreDataSource() async {
    let store = makeStore()
    let dataSource = CardDataSource(cards: [.mock(id: nil)], hasNextPage: false, total: 1)

    await store.send(.updateMeldPieces(dataSource)) { state in
      state.content.relatedMeldPieces = state.content.relatedMeldPieces?.updating(page: 1, state: .data(dataSource))
    }
  }

  @Test func whenUpdatingMeldResult_shouldStoreDataSource() async {
    let store = makeStore()
    let dataSource = CardDataSource(cards: [.mock(id: nil)], hasNextPage: false, total: 1)

    await store.send(.updateMeldResult(dataSource)) { state in
      state.content.relatedMeldResult = state.content.relatedMeldResult?.updating(page: 1, state: .data(dataSource))
    }
  }

  @Test func whenRelatedFetchReturnsNothing_shouldHideSection() async {
    let store = makeStore()

    // When a fetch finds nothing it still reports an empty data source.
    await store.send(.updateRelatedTokens(emptyDataSource)) { state in
      state.content.relatedTokens = state.content.relatedTokens?.updating(page: 1, state: .data(self.emptyDataSource))
    }

    // Then the section reads as absent so the view never builds it.
    #expect(store.state.content.relatedTokens?.state.value == nil)
  }

  @Test func whenShowingLastVariant_shouldFetchNextPage() async {
    let store = makeStore()
    store.exhaustivity = .off
    let dataSource = CardDataSource(
      cards: MockCardDetailRequestClient.generateMockCards(number: 3),
      hasNextPage: true,
      total: 10
    )

    // Given
    await store.send(.updateVariants(dataSource, page: 1)) { state in
      state.content.variants = state.content.variants.updating(page: 1, state: .data(dataSource))
    }

    // When the last variant comes into view.
    await store.send(.didShowVariant(index: 2))

    // Then
    await store.receive(.fetchVariants(card: card, page: 2))

    await store.finish()
  }

  @Test func whenShowingVariantBeforeTheLast_shouldNotPaginate() async {
    let store = makeStore()
    let dataSource = CardDataSource(
      cards: MockCardDetailRequestClient.generateMockCards(number: 3),
      hasNextPage: true,
      total: 10
    )

    // Given
    await store.send(.updateVariants(dataSource, page: 1)) { state in
      state.content.variants = state.content.variants.updating(page: 1, state: .data(dataSource))
    }

    // When / Then no pagination is triggered.
    await store.send(.didShowVariant(index: 0))
  }

  @Test func whenThereIsNoNextPage_shouldNotPaginate() async {
    let store = makeStore()
    let dataSource = CardDataSource(
      cards: MockCardDetailRequestClient.generateMockCards(number: 3),
      hasNextPage: false,
      total: 3
    )

    // Given
    await store.send(.updateVariants(dataSource, page: 1)) { state in
      state.content.variants = state.content.variants.updating(page: 1, state: .data(dataSource))
    }

    // When / Then no pagination is triggered.
    await store.send(.didShowVariant(index: 2))
  }

  @Test func whenViewRulingsTapped_shouldNotChangeState() async {
    let store = makeStore()

    await store.send(.viewRulingsTapped)
  }

  @Test func whenSelectingVariant_shouldNotChangeState() async {
    let store = makeStore()

    await store.send(.didSelectVariant(card: card, queryType: queryType))
  }
}
