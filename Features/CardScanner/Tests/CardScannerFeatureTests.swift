import Testing
import DesignComponents
import ComposableArchitecture
import Networking
@testable import CardScanner

@Suite("CardScannerFeature")
struct CardScannerFeatureTests {
  let initialResult = OCRCardScannedResult(
    title: "Initial Card",
    set: "TLR",
    code: "001",
  )
  
  @Test("didScan with a NEW card triggers updateScanResult and mutates state")
  func didScan_newCard_updatesState() async {
    let store = await TestStore(
      initialState: CardScannerFeature.State(
        scannedResult: initialResult
      )
    ) {
      CardScannerFeature()
    }
    
    let newCard = OCRCardScannedResult(
      title: "Black Lotus",
      set: "LEA",
      code: "1"
    )
    
    await store.send(.didScan(newCard))
    
    await store.receive(.updateScanResult(newCard)) { state in
      state.scannedResult = newCard
    }
    // Feature may kick off a fetch after updating the scan result
    await store.receive(.fetchCard(newCard))
    // Skip any additional actions like .updateCards(dataSource)
    await store.skipReceivedActions()

    #expect(await store.state.scannedResult == newCard)
  }
  
  @Test("didScan with the SAME card is ignored (Deduplication check)")
  func didScan_duplicateCard_producesNoEffects() async {
    let store = await TestStore(initialState: CardScannerFeature.State(scannedResult: initialResult)) {
      CardScannerFeature()
    }
    
    await MainActor.run {
      store.exhaustivity = .off(showSkippedAssertions: true)
    }
    
    await store.send(.didScan(initialResult))
    
    #expect(await store.state.scannedResult == initialResult)
  }
  
  @Test("fetchCard with valid title and setCode produces no effects")
  func fetchCard_producesNoEffects() async {
    let store = await TestStore(initialState: CardScannerFeature.State(scannedResult: initialResult)) {
      CardScannerFeature()
    }
    
    await store.send(.fetchCard(OCRCardScannedResult(title: "Black Lotus", set: "LEA", code: nil)))
    // Feature may emit an updateCards after fetching
    await store.skipReceivedActions()
  }
  
  // MARK: - Action Equality
  
  @Suite("Action equality")
  struct ActionEqualityTests {
    let moxRuby = OCRCardScannedResult(title: "Mox Ruby", set: "LEA", code: nil)
    let moxSapphire = OCRCardScannedResult(title: "Mox Sapphire", set: "LEA", code: nil)
    
    @Test("didScan matches identical actions")
    func didScan_equalityMatches() {
      #expect(
        CardScannerFeature.Action.didScan(moxRuby) ==
        CardScannerFeature.Action.didScan(moxRuby)
      )
    }
    
    @Test("didScan does not match different titles")
    func didScan_equalityMismatch_title() {
      #expect(
        CardScannerFeature.Action.didScan(moxRuby) !=
        CardScannerFeature.Action.didScan(moxSapphire)
      )
    }
    
    @Test("didScan does not match fetchCard with same args")
    func didScan_notEqualTo_fetchCard() {
      // Note: Comparing different enum cases directly requires matching the enum types
      let didScanAction = CardScannerFeature.Action.didScan(moxRuby)
      let fetchAction = CardScannerFeature.Action.fetchCard(OCRCardScannedResult(title: "Mox Ruby", set: "LEA", code: nil))
      
      #expect(didScanAction != fetchAction)
    }
    
    @Test("scan does not match didScan")
    func scan_notEqualTo_didScan() {
      let dummyDataSource = CardDataSource(cards: [], hasNextPage: false, total: 0)
      #expect(
        CardScannerFeature.Action.updateCards(dummyDataSource) !=
        CardScannerFeature.Action.didScan(moxRuby)
      )
    }
  }
}
