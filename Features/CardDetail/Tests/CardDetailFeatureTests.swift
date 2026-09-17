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
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }
  }

  private var emptyDataSource: CardDataSource {
    CardDataSource(cards: [], hasNextPage: false, total: 0)
  }

  @Test func whenInitialised_shouldHoldTheCard() {
    let state = CardDetailFeature.State(card: card, queryType: queryType)

    #expect(state.variants.state.isInitial)
    #expect(state.id == card.id)
    #expect(state.content.card == card)
  }

  @Test func whenViewAppeared_shouldDeliverSectionsAndPriceHistoryAsTwoActions() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When
    await store.send(.viewAppeared)

    // Should
    await store.receive(\.updateAdditionalInformation)
    await store.receive(\.updatePriceHistory)

    // Then the set icon and first variants page land together.
    #expect(store.state.setIconURL == URL(string: "iconSVGURI"))
    #expect(store.state.variants.state.value?.cardDetails.isEmpty == false)

    await store.finish()
  }

  @Test func whenViewAppearedTwice_shouldOnlyLoadOnce() async {
    let store = makeStore()
    store.exhaustivity = .off

    // Given
    await store.send(.viewAppeared)
    await store.finish()
    await store.skipReceivedActions()

    // When the page is rebuilt, for example after swiping away and back.
    await store.send(.viewAppeared)

    // Then nothing loads again, because everything has already landed.
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
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }
    store.exhaustivity = .off

    // Given the set icon is already known from the query type.
    #expect(store.state.setIconURL == URL(string: set.iconSvgUri))

    // When
    await store.send(.viewAppeared)

    // Should skip the set icon fetch, keeping the icon from the query type.
    await store.receive(\.updateAdditionalInformation)
    #expect(store.state.setIconURL == URL(string: set.iconSvgUri))

    await store.finish()
  }

  private func information(
    setIconURL: URL? = nil,
    variants: CardDataSource? = nil,
    relatedTokens: CardDataSource? = nil,
    relatedComboPieces: CardDataSource? = nil,
    relatedMeldPieces: CardDataSource? = nil,
    relatedMeldResult: CardDataSource? = nil
  ) -> CardDetailFeature.AdditionalInformation {
    CardDetailFeature.AdditionalInformation(
      setIconURL: setIconURL,
      variants: variants ?? emptyDataSource,
      relatedTokens: relatedTokens ?? emptyDataSource,
      relatedComboPieces: relatedComboPieces ?? emptyDataSource,
      relatedMeldPieces: relatedMeldPieces ?? emptyDataSource,
      relatedMeldResult: relatedMeldResult ?? emptyDataSource
    )
  }

  @Test func whenAdditionalInformationArrives_shouldStoreEverySection() async {
    let store = makeStore()
    let url = URL(string: "https://mooligan.com/icon.svg")
    let variants = CardDataSource(cards: [.mock(id: nil)], hasNextPage: true, total: 1)
    let tokens = CardDataSource(cards: [.mock(id: nil)], hasNextPage: false, total: 1)
    let comboPieces = CardDataSource(cards: [.mock(id: nil)], hasNextPage: false, total: 1)
    let meldPieces = CardDataSource(cards: [.mock(id: nil)], hasNextPage: false, total: 1)
    let meldResult = CardDataSource(cards: [.mock(id: nil)], hasNextPage: false, total: 1)

    await store.send(.updateAdditionalInformation(information(
      setIconURL: url,
      variants: variants,
      relatedTokens: tokens,
      relatedComboPieces: comboPieces,
      relatedMeldPieces: meldPieces,
      relatedMeldResult: meldResult
    ))) { state in
      state.setIconURL = url
      state.variants = state.variants.updating(page: 1, state: .data(variants))
      state.relatedTokens = state.relatedTokens?.updating(page: 1, state: .data(tokens))
      state.relatedComboPieces = state.relatedComboPieces?.updating(page: 1, state: .data(comboPieces))
      state.relatedMeldPieces = state.relatedMeldPieces?.updating(page: 1, state: .data(meldPieces))
      state.relatedMeldResult = state.relatedMeldResult?.updating(page: 1, state: .data(meldResult))
    }
  }

  @Test func whenAdditionalInformationHasNoSetIcon_shouldKeepExistingURL() async {
    let store = makeStore()
    let url = URL(string: "https://mooligan.com/icon.svg")

    // Given
    await store.send(.updateAdditionalInformation(information(setIconURL: url))) { state in
      state.setIconURL = url
      state.variants = state.variants.updating(page: 1, state: .data(self.emptyDataSource))
      state.relatedTokens = state.relatedTokens?.updating(page: 1, state: .data(self.emptyDataSource))
      state.relatedComboPieces = state.relatedComboPieces?.updating(page: 1, state: .data(self.emptyDataSource))
      state.relatedMeldPieces = state.relatedMeldPieces?.updating(page: 1, state: .data(self.emptyDataSource))
      state.relatedMeldResult = state.relatedMeldResult?.updating(page: 1, state: .data(self.emptyDataSource))
    }

    // When / Then the nil is ignored rather than clearing the icon.
    await store.send(.updateAdditionalInformation(information()))
  }

  @Test func whenUpdatingVariants_shouldStoreDataSourceAndPage() async {
    let store = makeStore()
    let dataSource = CardDataSource(cards: [.mock(id: nil)], hasNextPage: true, total: 1)

    await store.send(.updateVariants(dataSource, page: 2)) { state in
      state.variants = state.variants.updating(page: 2, state: .data(dataSource))
    }
  }

  @Test func whenRelatedFetchReturnsNothing_shouldHideSection() async {
    let store = makeStore()
    store.exhaustivity = .off

    // When a fetch finds nothing it still reports an empty data source.
    await store.send(.updateAdditionalInformation(information()))

    // Then the section reads as absent so the view never builds it.
    #expect(store.state.relatedTokens?.state.value == nil)
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
      state.variants = state.variants.updating(page: 1, state: .data(dataSource))
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
      state.variants = state.variants.updating(page: 1, state: .data(dataSource))
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
      state.variants = state.variants.updating(page: 1, state: .data(dataSource))
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
