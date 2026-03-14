import Testing
import ComposableArchitecture
import Networking
@testable import CardScanner

// MARK: - CardScannerFeature Tests

@Suite("CardScannerFeature")
struct CardScannerFeatureTests {
  
  // MARK: - scan
  
  @Test("scan produces no effects")
  @MainActor
  func scan_producesNoEffects() async {
    let store = TestStore(initialState: CardScannerFeature.State()) {
      CardScannerFeature()
    }
    
    await store.send(.scan)
  }
  
  // MARK: - didScan
  
  @Test("didScan with valid title and setCode produces no effects")
  @MainActor
  func didScan_producesNoEffects() async {
    let store = TestStore(initialState: CardScannerFeature.State()) {
      CardScannerFeature()
    }
    
    await store.send(.didScan(title: "Black Lotus", setCode: "LEA"))
  }
  
  // MARK: - fetchCard
  
  @Test("fetchCard with valid title and setCode produces no effects")
  @MainActor
  func fetchCard_producesNoEffects() async {
    let store = TestStore(initialState: CardScannerFeature.State()) {
      CardScannerFeature()
    }
    
    await store.send(.fetchCard(title: "Black Lotus", setCode: "LEA"))
  }
  
  // MARK: - updateCards
  
  @Test("updateCards with nil produces no effects")
  @MainActor
  func updateCards_nil_producesNoEffects() async {
    let store = TestStore(initialState: CardScannerFeature.State()) {
      CardScannerFeature()
    }
    
    await store.send(.updateCards(nil))
  }
  
//  @Test("updateCards with a value produces no effects")
//  @MainActor
//  func updateCards_withValue_producesNoEffects() async {
//    let store = TestStore(initialState: CardScannerFeature.State()) {
//      CardScannerFeature()
//    }
//    
//    let mockDataSource = CardDataSource(/* mock values */)
//    await store.send(.updateCards(mockDataSource))
//  }
  
  // MARK: - Action Equality
  
  @Suite("Action equality")
  struct ActionEqualityTests {
    
    @Test("didScan matches identical actions")
    func didScan_equalityMatches() {
      #expect(
        CardScannerFeature.Action.didScan(title: "Mox Ruby", setCode: "LEA") ==
        CardScannerFeature.Action.didScan(title: "Mox Ruby", setCode: "LEA")
      )
    }
    
    @Test("didScan does not match different titles")
    func didScan_equalityMismatch_title() {
      #expect(
        CardScannerFeature.Action.didScan(title: "Mox Ruby", setCode: "LEA") !=
        CardScannerFeature.Action.didScan(title: "Mox Sapphire", setCode: "LEA")
      )
    }
    
    @Test("didScan does not match fetchCard with same args")
    func didScan_notEqualTo_fetchCard() {
      #expect(
        CardScannerFeature.Action.didScan(title: "Mox Ruby", setCode: "LEA") !=
        CardScannerFeature.Action.fetchCard(title: "Mox Ruby", setCode: "LEA")
      )
    }
    
    @Test("scan does not match didScan")
    func scan_notEqualTo_didScan() {
      #expect(
        CardScannerFeature.Action.scan !=
        CardScannerFeature.Action.didScan(title: "Mox Ruby", setCode: "LEA")
      )
    }
  }
}
