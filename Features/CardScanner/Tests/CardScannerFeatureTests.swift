import Testing
import DesignComponents
import ComposableArchitecture
import Networking
@testable import CardScanner

// MARK: - CardScannerFeature Tests

@Suite("CardScannerFeature")
struct CardScannerFeatureTests {
  
  // A helper initial result to start our test states with
  let initialResult = OCRCardScannedResult(title: "Initial Card", setCode: "000")
  
  // MARK: - scan
  
  @Test("scan produces no effects")
  @MainActor
  func scan_producesNoEffects() async {
    let store = TestStore(initialState: CardScannerFeature.State(scannedResult: initialResult)) {
      CardScannerFeature()
    }
    
    await store.send(.scan)
  }
  
  // MARK: - didScan
  
  @Test("didScan with a NEW card triggers updateScanResult and mutates state")
  @MainActor
  func didScan_newCard_updatesState() async {
    let store = TestStore(initialState: CardScannerFeature.State(scannedResult: initialResult)) {
      CardScannerFeature()
    }
    
    let newCard = OCRCardScannedResult(title: "Black Lotus", setCode: "LEA")
    
    // 1. Send the scan
    await store.send(.didScan(newCard))
    
    // 2. Assert that TCA receives the effect and updates the state correctly
    // We use \.updateScanResult to target the specific case
    await store.receive(.updateScanResult(newCard)) { state in
      state.scannedResult = newCard
    }
  }
  
  @Test("didScan with the SAME card is ignored (Deduplication check)")
  @MainActor
  func didScan_duplicateCard_producesNoEffects() async {
    let store = TestStore(initialState: CardScannerFeature.State(scannedResult: initialResult)) {
      CardScannerFeature()
    }
    
    // Send the exact same card that is already in the state
    await store.send(.didScan(initialResult))
    
    // No `store.receive` is needed here! If the guard statement works,
    // the effect is `.none`, and TestStore will pass automatically.
  }
  
  // MARK: - fetchCard
  
  @Test("fetchCard with valid title and setCode produces no effects")
  @MainActor
  func fetchCard_producesNoEffects() async {
    let store = TestStore(initialState: CardScannerFeature.State(scannedResult: initialResult)) {
      CardScannerFeature()
    }
    
    await store.send(.fetchCard(title: "Black Lotus", setCode: "LEA"))
  }
  
  // MARK: - updateCards
  
  @Test("updateCards with nil produces no effects")
  @MainActor
  func updateCards_nil_producesNoEffects() async {
    let store = TestStore(initialState: CardScannerFeature.State(scannedResult: initialResult)) {
      CardScannerFeature()
    }
    
    await store.send(.updateCards(nil))
  }
  
  // MARK: - Action Equality
  
  @Suite("Action equality")
  struct ActionEqualityTests {
    
    let moxRuby = OCRCardScannedResult(title: "Mox Ruby", setCode: "LEA")
    let moxSapphire = OCRCardScannedResult(title: "Mox Sapphire", setCode: "LEA")
    
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
      let fetchAction = CardScannerFeature.Action.fetchCard(title: "Mox Ruby", setCode: "LEA")
      
      #expect(didScanAction != fetchAction)
    }
    
    @Test("scan does not match didScan")
    func scan_notEqualTo_didScan() {
      #expect(
        CardScannerFeature.Action.scan !=
        CardScannerFeature.Action.didScan(moxRuby)
      )
    }
  }
}
