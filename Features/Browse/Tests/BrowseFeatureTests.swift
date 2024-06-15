@testable import Browse
import ComposableArchitecture
import Networking
import XCTest

private let gameSet = MockGameSet()

final actor MockBrowseRequestClient: GameSetRequestClient {
  typealias Model = MockGameSet
  
  func getAllSets() -> [MockGameSet] {
    return [gameSet]
  }
}

final class BrowseFeatureTests: XCTestCase {
  private var store: TestStore<Feature<MockBrowseRequestClient>.State, Feature<MockBrowseRequestClient>.Action>!
  
  override func setUp() {
    super.setUp()
    
    store = TestStore(initialState: Feature.State()) {
      Feature(client: MockBrowseRequestClient())
    }
  }
  
  override func tearDown() {
    store = nil
    super.tearDown()
  }
}

extension BrowseFeatureTests {
  @MainActor
  func test_sendShowSets_shouldUpdateState() async {
    let expectedSets = [MockGameSet()]
    
    await store.send(.updateSets(expectedSets)) { state in
      state.isLoading = false
      state.sets = expectedSets
    }
  }
  
  @MainActor
  func test_sendDidSelectSet_shouldSetSelectedSet() async {
    let expectedSet = MockGameSet()
    
    await store.send(.updateSets([expectedSet])) { state in
      state.sets = [expectedSet]
    }
    
    await store.send(.didSelectSet(index: 0)) { state in
      state.selectedSet = expectedSet
    }
  }
  
  @MainActor
  func test_sendViewAppeared_shouldFetchSets() async {
    await store.send(.viewAppeared)
    
    await store.receive(.fetchSets) { state in
      state.isLoading = true
      state.sets = []
    }
    
    await store.receive(.updateSets([gameSet])) { state in
      state.sets = [gameSet]
      state.isLoading = false
    }
  }

  @MainActor
  func test_sendFetchSets_shouldSetSets_withValue() async {
    let expectedSets = [gameSet]
    
    await store.send(.fetchSets) { state in
      state.isLoading = true
    }
    
    await store.receive(.updateSets(expectedSets)) { state in
      state.sets = [gameSet]
      state.isLoading = false
    }
  }
  
  @MainActor
  func test_setRowViewModel() async {
    await store.send(.updateSets([gameSet])) { state in
      state.sets = [gameSet]
    }
    
    let given = store.state.getSetRowViewModel(at: 0, colorScheme: .light)
    let expected = SetRow.ViewModel(
      set: gameSet,
      selectedSet: nil,
      index: 0,
      colorScheme: .light
    )
    
    XCTAssertEqual(given, expected)
  }
}
