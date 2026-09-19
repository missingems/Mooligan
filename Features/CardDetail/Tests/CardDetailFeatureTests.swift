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

  private func makeStore(
    _ state: CardDetailFeature.State? = nil,
    client: any MagicCardDetailRequestClient = MockCardDetailRequestClient(),
    priceHistory: any PriceHistoryClient = MockPriceHistoryClient()
  ) -> TestStoreOf<CardDetailFeature> {
    TestStore(
      initialState: state ?? CardDetailFeature.State(card: card, queryType: queryType)
    ) {
      CardDetailFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.cardDetailRequestClient = client
      $0.priceHistoryClient = priceHistory
    }
  }

  private func imageUris(_ face: String) -> Card.ImageUris {
    Card.ImageUris(
      small: nil,
      normal: imageURL(face).absoluteString,
      large: nil,
      png: nil,
      artCrop: nil,
      borderCrop: nil
    )
  }

  private func imageURL(_ face: String) -> URL {
    URL(string: "https://cards.scryfall.io/normal/\(face).jpg")!
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

  @Test func whenOpenedWithItsBackOnShow_shouldKeepThatFace() {
    // The Query grid lets a card be turned over before it is opened, and hands over the face it
    // shows; the page must not turn it back to the front.
    let transforming = transformingCard
    let showingBack = DisplayableCardImage(transforming)?.toggled()

    let state = CardDetailFeature.State(
      card: transforming,
      displayableCardImage: showingBack,
      queryType: queryType
    )

    #expect(showingBack?.faceDirection == .back)
    #expect(state.displayableCardImage == showingBack)
  }

  @Test func whenViewAppeared_shouldDeliverSectionsAndPriceHistoryAsTwoActions() async {
    let set = MockGameSetRequestClient.mockSets[0]
    let otherPrints = MockCardDetailRequestClient.generateMockCards(number: 2)
    let store = makeStore(client: VariantsPageClient(
      variants: ObjectList(data: [card] + otherPrints, hasMore: true, totalCards: 3),
      set: set
    ))
    // The chart's display is built from the whole mock feed, which other suites cover; this test is
    // about how the loads come back, so it asserts the sections exactly and the chart by its status.
    store.exhaustivity = .off
    let prints = CardDataSource(cards: [card] + otherPrints, hasNextPage: true, total: 3)
    let expected = information(setIconURL: URL(string: set.iconSvgUri), variants: prints)

    // When
    await store.send(.viewAppeared)

    // Then the set icon, the first page of prints and the related sections land in one action.
    await store.receive(.updateAdditionalInformation(expected)) { state in
      state.setIconURL = URL(string: set.iconSvgUri)
      state.variants = state.variants.updating(page: 1, state: .data(prints))
    }
    #expect(store.state.variants.state.value == prints)

    // And the price history in another.
    await store.receive(\.updatePriceHistory)
    #expect(store.state.priceHistory.status == .loaded)

    await store.finish()
  }

  @Test func whenViewAppearedTwice_shouldOnlyLoadOnce() async {
    let client = VariantsPageClient(variants: ObjectList(data: [card], hasMore: false, totalCards: 1))
    let priceHistory = CountingMockClient()
    let store = makeStore(client: client, priceHistory: priceHistory)

    // Given everything has landed from the first appearance.
    store.exhaustivity = .off
    await store.send(.viewAppeared)
    await store.finish()
    await store.skipReceivedActions()
    #expect(client.requestedPages.value == [1])
    #expect(await priceHistory.calls == 1)
    #expect(store.state.variants.state.isInitial == false)
    #expect(store.state.priceHistory.status == .loaded)

    // When the page is rebuilt, for example after swiping away and back.
    store.exhaustivity = .on
    await store.send(.viewAppeared)
    await store.finish()

    // Then nothing loads again: the exhaustive store saw no state change and no action, and neither
    // client was asked a second time.
    #expect(client.requestedPages.value == [1])
    #expect(await priceHistory.calls == 1)
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

  @Test func whenRelatedFetchesFindNothing_shouldStoreEachSectionAsLoadedButAbsent() async {
    let store = makeStore()
    let empty = emptyDataSource

    // When every fetch finds nothing, each still reports an empty data source.
    await store.send(.updateAdditionalInformation(information())) { state in
      state.variants = state.variants.updating(page: 1, state: .data(empty))
      state.relatedTokens = state.relatedTokens?.updating(page: 1, state: .data(empty))
      state.relatedComboPieces = state.relatedComboPieces?.updating(page: 1, state: .data(empty))
      state.relatedMeldPieces = state.relatedMeldPieces?.updating(page: 1, state: .data(empty))
      state.relatedMeldResult = state.relatedMeldResult?.updating(page: 1, state: .data(empty))
    }

    // Then each section has finished loading, and reads as absent so the view never builds it.
    #expect(store.state.relatedTokens?.state.isInitial == false)
    #expect(store.state.relatedTokens?.state.value == nil)
    #expect(store.state.relatedComboPieces?.state.value == nil)
    #expect(store.state.relatedMeldPieces?.state.value == nil)
    #expect(store.state.relatedMeldResult?.state.value == nil)
  }

  @Test func whenShowingLastVariant_shouldFetchNextPageAndAddItsNewPrints() async {
    let shownCards = MockCardDetailRequestClient.generateMockCards(number: 3)
    let nextPrints = MockCardDetailRequestClient.generateMockCards(number: 2)
    // The next page repeats the card on show and a print already listed, as Scryfall's pages can.
    let client = VariantsPageClient(
      variants: ObjectList(data: [card, shownCards[2]] + nextPrints, hasMore: false, totalCards: 5)
    )
    let store = makeStore(client: client)
    let shown = CardDataSource(cards: shownCards, hasNextPage: true, total: 10)
    let merged = CardDataSource(cards: shownCards + nextPrints, hasNextPage: false, total: 5)

    // Given
    await store.send(.updateVariants(shown, page: 1)) { state in
      state.variants = state.variants.updating(page: 1, state: .data(shown))
    }

    // When the last variant comes into view.
    await store.send(.didShowVariant(index: 2))

    // Then the next page is asked for, and only its new prints are added after the ones shown,
    // with the paging and total the response gives.
    await store.receive(.fetchVariants(card: card, page: 2))
    await store.receive(.updateVariants(merged, page: 2)) { state in
      state.variants = state.variants.updating(page: 2, state: .data(merged))
    }
    #expect(client.requestedPages.value == [2])
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

  // MARK: - Prints

  @Test func whenFetchingPrintsWithNoneHeld_shouldListThePageWithoutTheCardItself() async {
    let otherPrints = MockCardDetailRequestClient.generateMockCards(number: 2)
    let store = makeStore(client: VariantsPageClient(
      variants: ObjectList(data: [card] + otherPrints, hasMore: true, totalCards: 3)
    ))
    let empty = emptyDataSource
    let expected = CardDataSource(cards: otherPrints, hasNextPage: true, total: 3)

    // Given no prints are held.
    await store.send(.updateVariants(empty, page: 1)) { state in
      state.variants = state.variants.updating(page: 1, state: .data(empty))
    }

    // When
    await store.send(.fetchVariants(card: card, page: 1))

    // Then the page becomes the list, without the card on show, paging as the response says.
    await store.receive(.updateVariants(expected, page: 1)) { state in
      state.variants = state.variants.updating(page: 1, state: .data(expected))
    }
  }

  @Test func whenThePageLeavesOutPaging_shouldTreatItAsTheLastPageWithNoTotal() async {
    let otherPrint = Card.mock(id: nil)
    let store = makeStore(client: VariantsPageClient(variants: ObjectList(data: [otherPrint])))
    let empty = emptyDataSource
    let expected = CardDataSource(cards: [otherPrint], hasNextPage: false, total: 0)

    // Given no prints are held.
    await store.send(.updateVariants(empty, page: 1)) { state in
      state.variants = state.variants.updating(page: 1, state: .data(empty))
    }

    // When the response carries neither `has_more` nor `total_cards`.
    await store.send(.fetchVariants(card: card, page: 1))

    // Then
    await store.receive(.updateVariants(expected, page: 1)) { state in
      state.variants = state.variants.updating(page: 1, state: .data(expected))
    }
  }

  @Test func whenTheNextPageOfPrintsFails_shouldKeepThePrintsAlreadyShown() async {
    let client = VariantsPageClient(variants: nil)
    let store = makeStore(client: client)
    let shown = CardDataSource(
      cards: MockCardDetailRequestClient.generateMockCards(number: 3),
      hasNextPage: true,
      total: 10
    )

    // Given
    await store.send(.updateVariants(shown, page: 1)) { state in
      state.variants = state.variants.updating(page: 1, state: .data(shown))
    }

    // When the last print comes into view and the next page cannot be fetched.
    // The page count the failure leaves behind is asserted as a known issue below rather than here,
    // so this part does not pin it.
    store.exhaustivity = .off
    await store.send(.didShowVariant(index: 2))
    await store.receive(.fetchVariants(card: card, page: 2))
    await store.receive(\.updateVariants)

    // Then the prints stay exactly as they were, still offering a next page.
    #expect(store.state.variants.state == .data(shown))

    // And when the reader comes back to the last print, the page that failed is asked for again.
    await store.send(.didShowVariant(index: 2))
    await store.finish()
    withKnownIssue("A failed page still moves the page count on, so the next scroll asks for the page after it") {
      #expect(client.requestedPages.value == [2, 2])
    }
  }

  @Test func whenPrintsFailWithNoneHeld_shouldStillHoldNone() async {
    let store = makeStore(client: VariantsPageClient(variants: nil))
    let empty = emptyDataSource

    // Given no prints are held.
    await store.send(.updateVariants(empty, page: 1)) { state in
      state.variants = state.variants.updating(page: 1, state: .data(empty))
    }

    // When
    await store.send(.fetchVariants(card: card, page: 1))

    // Then an empty list comes back, so the prints section stays hidden.
    await store.receive(.updateVariants(empty, page: 1))
  }

  @Test func whenTheSetCannotBeFetched_shouldDeliverTheSectionsWithoutASetIcon() async {
    var settled = CardDetailFeature.State(card: card, queryType: queryType)
    // Given price history and the pull odds have already settled, so appearing loads only the
    // sections.
    settled.priceHistory = PriceHistoryDisplay.make(card: card, state: .failed, labels: PriceHistoryLabels())
    settled.pullOdds = .unavailable
    let otherPrints = MockCardDetailRequestClient.generateMockCards(number: 2)
    let store = makeStore(settled, client: VariantsPageClient(
      variants: ObjectList(data: [card] + otherPrints, hasMore: true, totalCards: 3)
    ))
    // The page opens holding only its own card, so the first page is added after it, without
    // repeating it, and brings its own paging and total.
    let prints = CardDataSource(cards: [card] + otherPrints, hasNextPage: true, total: 3)
    let empty = emptyDataSource

    // When
    await store.send(.viewAppeared)

    // Then the sections still land together, with no icon for the set.
    await store.receive(.updateAdditionalInformation(information(setIconURL: nil, variants: prints))) { state in
      state.variants = state.variants.updating(page: 1, state: .data(prints))
      state.relatedTokens = state.relatedTokens?.updating(page: 1, state: .data(empty))
      state.relatedComboPieces = state.relatedComboPieces?.updating(page: 1, state: .data(empty))
      state.relatedMeldPieces = state.relatedMeldPieces?.updating(page: 1, state: .data(empty))
      state.relatedMeldResult = state.relatedMeldResult?.updating(page: 1, state: .data(empty))
    }
    #expect(store.state.setIconURL == nil)
  }

  // MARK: - Turning the card over

  /// A transforming card with an image on each face.
  private var transformingCard: Card {
    var transforming = card
    transforming.layout = .transform
    transforming.imageUris = nil
    transforming.cardFaces = [
      Card.Face(imageUris: imageUris("front"), manaCost: "", name: "Front"),
      Card.Face(imageUris: imageUris("back"), manaCost: "", name: "Back"),
    ]
    return transforming
  }

  @Test func whenATransformingCardIsTurnedOver_shouldShowItsBackThenItsFront() async {
    let transforming = transformingCard
    let store = makeStore(CardDetailFeature.State(card: transforming, queryType: queryType))
    let showingFront = DisplayableCardImage.transformable(
      direction: .front,
      frontImageURL: imageURL("front"),
      backImageURL: imageURL("back"),
      callToActionIconName: "arrow.left.arrow.right",
      id: transforming.id.uuidString
    )
    let showingBack = DisplayableCardImage.transformable(
      direction: .back,
      frontImageURL: imageURL("front"),
      backImageURL: imageURL("back"),
      callToActionIconName: "arrow.left.arrow.right",
      id: transforming.id.uuidString
    )

    // Given it opens on its front.
    #expect(store.state.displayableCardImage == showingFront)

    // When / Then each tap turns it to the other face, keeping both images.
    await store.send(.descriptionCallToActionTapped) { state in
      state.displayableCardImage = showingBack
    }
    await store.send(.descriptionCallToActionTapped) { state in
      state.displayableCardImage = showingFront
    }
  }

  @Test func whenAFlipCardIsTurnedOver_shouldTurnItUpsideDownThenBack() async {
    var flip = card
    flip.layout = .flip
    flip.imageUris = imageUris("flip")
    let store = makeStore(CardDetailFeature.State(card: flip, queryType: queryType))
    let upright = DisplayableCardImage.flippable(
      direction: .front,
      displayingImageURL: imageURL("flip"),
      callToActionIconName: "arrow.trianglehead.clockwise.rotate.90",
      id: flip.id.uuidString
    )
    let upsideDown = DisplayableCardImage.flippable(
      direction: .back,
      displayingImageURL: imageURL("flip"),
      callToActionIconName: "arrow.trianglehead.clockwise.rotate.90",
      id: flip.id.uuidString
    )

    // Given it opens upright.
    #expect(store.state.displayableCardImage == upright)

    // When / Then each tap turns it the other way up, on its one image.
    await store.send(.descriptionCallToActionTapped) { state in
      state.displayableCardImage = upsideDown
    }
    await store.send(.descriptionCallToActionTapped) { state in
      state.displayableCardImage = upright
    }
  }

  @Test func whenASingleFacedCardIsTurnedOver_shouldReportAnIssueAndStayAsItIs() async {
    var single = card
    single.imageUris = imageUris("single")
    let store = makeStore(CardDetailFeature.State(card: single, queryType: queryType))

    // Given
    #expect(store.state.displayableCardImage == .single(
      displayingImageURL: imageURL("single"),
      id: single.id.uuidString
    ))

    // When / Then the state is untouched, which the store asserts, and the tap is reported.
    await withKnownIssue {
      await store.send(.descriptionCallToActionTapped)
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("isn't available to single face card") }
    }
  }

  @Test func whenACardWithoutAnImageIsTurnedOver_shouldReportAnIssueAndStayAsItIs() async {
    var imageless = card
    imageless.imageUris = nil
    let store = makeStore(CardDetailFeature.State(card: imageless, queryType: queryType))

    // Given
    #expect(store.state.displayableCardImage == nil)

    // When / Then the state is untouched, which the store asserts, and the tap is reported.
    await withKnownIssue {
      await store.send(.descriptionCallToActionTapped)
    } matching: { issue in
      issue.comments.contains { $0.rawValue.contains("isn't available to single face card") }
    }
  }
}
