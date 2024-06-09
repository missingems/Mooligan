@testable import CardDetail
import ComposableArchitecture
@testable import Networking
import XCTest

final class FeatureTests: XCTestCase {
  typealias Client = Networking.TestMagicCardDetailRequestClient
  let cards = MagicCardFixture.stub
  let card = MagicCardFixture.stub[0]
  
  func test_whenStateEntryPointIsQuery_startShouldFetchSet() {
    let state = Feature<Client>.State(card: card, entryPoint: .query)
    XCTAssertEqual(state.start, .fetchSet)
  }
  
  func test_whenStateEntryPointIsSet_startShouldFetchVariants() {
    let state = Feature<Client>.State(card: card, entryPoint: .query)
    XCTAssertEqual(state.start, .fetchSet)
  }
  
  @MainActor
  func test_whenViewAppeared_withEntryPointAsQuery_shouldSendFetchSet_shouldUpdateSetIconURL() async {
    let store = TestStore(
      initialState: Feature.State(card: card, entryPoint: .query),
      reducer: {
        Feature(client: Client())
      }
    )
    
    await store.send(.viewAppeared)
    await store.receive(.fetchSet)
    await store.receive(.updateSetIconURL(URL(string: "https://mooligan.com")!)) { state in
      state.content.setIconURL = URL(string: "https://mooligan.com")
    }
  }
  
  @MainActor
  func test_whenViewAppeared_withEntryPointAsSet_shouldSendFetchVariants_shouldUpdateVariants() async {
    let store = TestStore(
      initialState: Feature.State(card: card, entryPoint: .set(MockGameSet())),
      reducer: { Feature(client: Client()) }
    )
    
    await store.send(.viewAppeared)
    await store.receive(.fetchVariants)
    await store.receive(.updateVariants(cards)) { [weak self] state in
      guard let cards = self?.cards else { return }
      state.content.variants = cards
    }
  }
}
