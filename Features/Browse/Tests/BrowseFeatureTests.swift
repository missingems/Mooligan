@testable import Browse
import ComposableArchitecture
import Networking
import XCTest

struct MockGameSet: GameSet {
  var id = UUID()
  var code = "123"
  var numberOfCards = 1
  var name = "Stub"
  var iconURL = URL(string: "https://mooligan.com")
}

private let gameSet = MockGameSet()

final actor MockBrowseRequestClient: BrowseRequestClient {
  typealias Model = MockGameSet
  
  func getAllSets() -> [MockGameSet] {
    return [gameSet]
  }
}

final class BrowseFeatureTests: XCTestCase {
  private var store: TestStore<Feature<MockBrowseRequestClient>.State, Feature<MockBrowseRequestClient>.Action>!
  
  override func setUp() {
    super.setUp()
    
    store = TestStore(
      initialState: Feature<MockBrowseRequestClient>.State()
    ) {
      Feature<MockBrowseRequestClient>(client: MockBrowseRequestClient())
    }
  }
  
  override func tearDown() {
    store = nil
    super.tearDown()
  }
}

// MARK: - Test State Changes

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
    
    await store.send(.didSelectSet(expectedSet)) { state in
      state.selectedSet = expectedSet
    }
  }
}

// MARK: - Test Effects

extension BrowseFeatureTests {
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
}

