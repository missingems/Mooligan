@testable import CardScanner
import CardDetail
import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit
import Testing

@MainActor struct CardScannerFeatureTests {
  private let card = Card.mock()

  private func makeStore() -> TestStoreOf<CardScannerFeature> {
    TestStore(initialState: CardScannerFeature.State()) {
      CardScannerFeature()
    }
  }

  @Test func whenInitialised_shouldStartLoading() {
    let state = CardScannerFeature.State()

    #expect(state.status == .loading)
    #expect(state.dataSource == nil)
    #expect(state.isMorphed == false)
    #expect(state.isScanningPaused == false)
    #expect(state.recentMatchIDs.isEmpty)
  }

  @Test func whenSyncCompleted_shouldStartScanning() async {
    let store = makeStore()

    await store.send(.syncCompleted) { state in
      state.status = .scanning
    }
  }

  @Test func whenUpdatingSafeAreas_shouldStoreThem() async {
    let store = makeStore()

    await store.send(.updateSafeAreas(top: 59, bottom: 34)) { state in
      state.topSafeArea = 59
      state.bottomSafeArea = 34
    }
  }

  @Test func whenUpdatingViewSize_shouldStoreIt() async {
    let store = makeStore()
    let size = CGSize(width: 402, height: 874)

    await store.send(.updateViewSize(size)) { state in
      state.viewSize = size
    }
  }

  @Test func whenUpdatingViewSizeToTheSameValue_shouldNotChangeState() async {
    let store = makeStore()
    let size = CGSize(width: 402, height: 874)

    // Given
    await store.send(.updateViewSize(size)) { state in
      state.viewSize = size
    }

    // When / Then the repeat is a no-op.
    await store.send(.updateViewSize(size))
  }

  @Test func whenTrackingCorners_shouldStoreThem() async {
    let store = makeStore()
    let corners = QuadCorners(
      topLeft: .zero,
      topRight: CGPoint(x: 1, y: 0),
      bottomRight: CGPoint(x: 1, y: 1),
      bottomLeft: CGPoint(x: 0, y: 1)
    )

    await store.send(.trackingCornersUpdated(corners)) { state in
      state.latestTrackedCorners = corners
    }
  }

  @Test func whenMorphed_shouldIgnoreTrackingCorners() async {
    let store = makeStore()
    let corners = QuadCorners(
      topLeft: .zero,
      topRight: CGPoint(x: 1, y: 0),
      bottomRight: CGPoint(x: 1, y: 1),
      bottomLeft: CGPoint(x: 0, y: 1)
    )

    // Given the card has morphed into the detail presentation.
    await store.send(.triggerMorph) { state in
      state.isMorphed = true
    }

    // When / Then tracking no longer moves the overlay.
    await store.send(.trackingCornersUpdated(corners))
  }

  @Test func whenTriggeringMorph_shouldMarkAsMorphed() async {
    let store = makeStore()

    await store.send(.triggerMorph) { state in
      state.isMorphed = true
    }
  }

  @Test func whenMorphAnimationFinished_shouldCompleteThenMergeVariants() async {
    let store = makeStore()

    // When
    await store.send(.morphAnimationFinished)

    // Should
    await store.receive(\.updateMorphAnimation) { state in
      state.isMorphAnimationComplete = true
    }

    // Then
    await store.receive(\.mergePendingVariants)
  }

  @Test func whenVariantsLoad_shouldHoldThemUntilTheMorphCompletes() async {
    let store = makeStore()

    // When variants arrive before the morph animation has finished.
    await store.send(.variantsLoaded([card])) { state in
      state.pendingVariants = [self.card]
    }

    // Then they stay pending rather than being merged in mid-animation.
    await store.receive(\.mergePendingVariants)

    #expect(store.state.pendingVariants == [card])
    #expect(store.state.dataSource == nil)
  }

  @Test func whenMergingVariants_shouldPutTheScannedCardFirst() async {
    let store = makeStore()
    store.exhaustivity = .off
    let variant = Card.mock(id: UUID())

    // Given a scanned card and a completed morph.
    await store.send(.singleCardFound(card, face: .front))
    await store.finish()
    await store.skipReceivedActions()

    await store.send(.updateMorphAnimation(isCompleted: true))
    await store.send(.variantsLoaded([variant, card]))
    await store.receive(\.mergePendingVariants)
    await store.finish()

    // Then the scanned card leads the list and is not duplicated.
    #expect(store.state.dataSource?.cardDetails.first?.card.id == card.id)
    #expect(store.state.dataSource?.cardDetails.count == 2)
    #expect(store.state.pendingVariants == nil)
  }

  // MARK: - Double-faced cards

  /// The database stores a card whose faces have their own images once per face.
  private let doubleFacedCardID = "318c363b-61cc-4e2f-8f86-a4287539ea07"

  private func doubleFacedCard(id: UUID = UUID()) -> Card {
    var card = Card.mock(id: id, name: "Front // Back")
    card.layout = .transform
    card.imageUris = nil
    card.cardFaces = [
      Card.Face(imageUris: faceImageUris("front"), manaCost: "", name: "Front"),
      Card.Face(imageUris: faceImageUris("back"), manaCost: "", name: "Back"),
    ]
    return card
  }

  private func faceImageUris(_ face: String) -> Card.ImageUris {
    Card.ImageUris(small: nil, normal: "mock://\(face)", large: nil, png: nil, artCrop: nil, borderCrop: nil)
  }

  private func makeStore(client: CardQueryRequestClientSpy) -> TestStoreOf<CardScannerFeature> {
    let store = TestStore(initialState: CardScannerFeature.State()) {
      CardScannerFeature()
    } withDependencies: {
      $0.cardQueryRequestClient = client
    }
    store.exhaustivity = .off
    return store
  }

  @Test func whenABackFaceMatchesThreeFrames_shouldLookUpItsCardAndShowTheBack() async {
    let card = doubleFacedCard(id: UUID(uuidString: doubleFacedCardID)!)
    let client = CardQueryRequestClientSpy(card: card)
    let store = makeStore(client: client)
    let backFace = MatchResult(id: "\(doubleFacedCardID)-face1", distance: 0.1)

    // When
    for _ in 0..<3 {
      await store.send(.internalMatchesFound([backFace]))
    }
    await store.receive(\.singleCardFound)
    await store.finish()

    // Then Scryfall is asked for the card, not the face, and the back is shown.
    #expect(client.requestedIDs.value == [doubleFacedCardID])
    #expect(store.state.status.displayTitle == "Back")
    #expect(store.state.dataSource?.cardDetails.first?.displayableCardImage?.faceDirection == .back)
  }

  @Test func whenTheFacesOfOneCardAlternate_shouldStillSettleOnTheLastFaceSeen() async {
    let card = doubleFacedCard(id: UUID(uuidString: doubleFacedCardID)!)
    let client = CardQueryRequestClientSpy(card: card)
    let store = makeStore(client: client)
    let front = MatchResult(id: "\(doubleFacedCardID)-face0", distance: 0.1)
    let back = MatchResult(id: "\(doubleFacedCardID)-face1", distance: 0.1)

    // When two similar faces take turns being the closest match.
    await store.send(.internalMatchesFound([front]))
    await store.send(.internalMatchesFound([back]))
    await store.send(.internalMatchesFound([front]))
    await store.receive(\.singleCardFound)
    await store.finish()

    // Then
    #expect(client.requestedIDs.value == [doubleFacedCardID])
    #expect(store.state.status.displayTitle == "Front")
    #expect(store.state.dataSource?.cardDetails.first?.displayableCardImage?.faceDirection == .front)
  }

  @Test func whenMergingPrintingsAfterABackScan_shouldKeepEveryPrintingOnItsBack() async {
    let scanned = doubleFacedCard()
    let printing = doubleFacedCard()
    let store = makeStore(client: CardQueryRequestClientSpy(card: scanned, printings: [printing, scanned]))

    // Given the back was scanned and the morph finished.
    await store.send(.singleCardFound(scanned, face: .back))
    await store.finish()
    await store.skipReceivedActions()
    await store.send(.updateMorphAnimation(isCompleted: true))

    // When
    await store.send(.mergePendingVariants)

    // Then the scanned card leads, and nothing turned back to its front.
    let details = store.state.dataSource?.cardDetails
    #expect(details?.map(\.card.id) == [scanned.id, printing.id])
    #expect(details?.map { $0.displayableCardImage?.faceDirection } == [.back, .back])
  }

  @Test func whenAReversibleCardIsScanned_shouldFindPrintingsByTheScannedFaceOracleID() async {
    var card = doubleFacedCard()
    card.layout = .reversibleCard
    card.oracleId = nil
    card.cardFaces?[0].oracleId = "front-oracle-id"
    card.cardFaces?[1].oracleId = "back-oracle-id"
    let client = CardQueryRequestClientSpy(card: card)
    let store = makeStore(client: client)

    // When
    await store.send(.singleCardFound(card, face: .back))
    await store.finish()

    // Then
    #expect(client.queries.value.map(\.oracleID) == ["back-oracle-id"])
  }

  @Test func whenTheScannedCardIsTurnedOver_shouldShowAndNameTheOtherFace() async {
    let card = doubleFacedCard()
    let store = makeStore(client: CardQueryRequestClientSpy(card: card))

    // Given the back was scanned.
    await store.send(.singleCardFound(card, face: .back))
    await store.finish()

    // When
    await store.send(.cardFaceToggled(card.id))

    // Then
    #expect(store.state.dataSource?.cardDetails.first?.displayableCardImage?.faceDirection == .front)
    #expect(store.state.status.displayTitle == "Front")
  }

  @Test func whenAScannedCardIsTapped_shouldOpenThePagerOnItAmongItsPrintings() async {
    let scanned = doubleFacedCard()
    let printing = doubleFacedCard()
    let store = makeStore(client: CardQueryRequestClientSpy(card: scanned, printings: [printing, scanned]))

    // Given the scan settled with its printings, and the printing turned over.
    await store.send(.singleCardFound(scanned, face: .front))
    await store.finish()
    await store.skipReceivedActions()
    await store.send(.updateMorphAnimation(isCompleted: true))
    await store.send(.mergePendingVariants)
    await store.send(.cardFaceToggled(printing.id))

    // When
    await store.send(.cardTapped(printing.id))
    await store.receive(\.cardPagerPrepared)

    // Then the pager opens on the tapped printing, on the face it was turned to.
    #expect(store.state.cardPager?.selectedId == printing.id)
    #expect(store.state.cardPager?.cards.ids.elements == [scanned.id, printing.id])
    #expect(store.state.cardPager?.cards[id: printing.id]?.displayableCardImage?.faceDirection == .back)
  }

  @Test func whenMergingWithoutAScannedCard_shouldDoNothing() async {
    let store = makeStore()

    // Given the morph completed but nothing was scanned.
    await store.send(.updateMorphAnimation(isCompleted: true)) { state in
      state.isMorphAnimationComplete = true
    }

    // When / Then
    await store.send(.mergePendingVariants)

    #expect(store.state.dataSource == nil)
  }

  @Test func whenResettingScan_shouldReturnToScanning() async {
    let store = makeStore()
    store.exhaustivity = .off

    // Given a scan in progress.
    await store.send(.triggerMorph)
    await store.send(.updateMorphAnimation(isCompleted: true))
    await store.send(.singleCardFound(card, face: .front))
    await store.finish()
    await store.skipReceivedActions()

    // When
    await store.send(.resetScan)
    await store.finish()

    // Then everything is cleared and scanning resumes.
    #expect(store.state.isMorphed == false)
    #expect(store.state.isMorphAnimationComplete == false)
    #expect(store.state.dataSource == nil)
    #expect(store.state.pendingVariants == nil)
    #expect(store.state.isProcessingFrame == false)
    #expect(store.state.isScanningPaused == false)
    #expect(store.state.latestTrackedCorners == nil)
    #expect(store.state.transientImage == nil)
    #expect(store.state.recentMatchIDs.isEmpty)
    #expect(store.state.status == .scanning)
  }
}

@MainActor struct ScannerStatusTests {
  @Test func whenLoading_shouldDescribeItself() {
    #expect(ScannerStatus.loading.displayTitle == "Loading...")
  }

  @Test func whenScanning_shouldDescribeItself() {
    #expect(ScannerStatus.scanning.displayTitle == "Scanning...")
  }

  @Test func whenScanFound_shouldDescribeItself() {
    #expect(ScannerStatus.scanFound.displayTitle == "Scan Found!")
  }

  @Test func whenShowingCardDetails_shouldUseTheCardTitle() {
    #expect(ScannerStatus.cardDetails(title: "Black Lotus", subtitle: "LEA").displayTitle == "Black Lotus")
  }
}
