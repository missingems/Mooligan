@testable import CardDetail
import ComposableArchitecture
@testable import Networking
import XCTest

final class FeatureTests: XCTestCase {
  typealias Client = Networking.MockMagicCardDetailRequestClient
  let card = CardBuilder.splitCard
  
  func test_whenStateEntryPointIsQuery_startShouldFetchSet() {
    let state = Feature<Client>.State(card: card, entryPoint: .query)
    XCTAssertEqual(state.start, .fetchSet(card: card))
  }
  
  func test_whenStateEntryPointIsSet_startShouldFetchVariants() {
    let state = Feature<Client>.State(card: card, entryPoint: .set(MockGameSet()))
    XCTAssertEqual(state.start, .fetchVariants(card: card))
  }
  
  @MainActor
  func test_whenViewAppeared_withEntryPointAsQuery_shouldSendFetchSet_shouldUpdateSetIconURL() async {
    let store = TestStore(
      initialState: Feature.State(card: card, entryPoint: .query),
      reducer: {
        Feature(client: Client())
      }
    )
    
    await store.send(.viewAppeared(initialAction: store.state.start))
    await store.receive(.fetchSet(card: card))
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
    
    await store.send(.viewAppeared(initialAction: store.state.start))
    await store.receive(.fetchVariants(card: card))
    await store.receive(.updateVariants([card])) { [weak self] state in
      guard let card = self?.card else { return }
      state.content.variants = [card]
    }
  }
}
