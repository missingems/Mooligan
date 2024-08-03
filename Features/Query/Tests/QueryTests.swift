@testable import Query
import ComposableArchitecture
import Networking
import XCTest

private let magicCard = MockMagicCard<MockMagicCardColor>()
private let gameSet = MockGameSet()

struct MockQueryRequestClient: MagicCardQueryRequestClient {
  func queryCards(_ query: QueryType) async throws -> ObjectList<[MockMagicCard<MockMagicCardColor>]> {
    return ObjectList(model: [magicCard], hasNextPage: true)
  }
}

final class QueryTests: XCTestCase {
  private var store: TestStore<Feature<MockQueryRequestClient>.State, Feature<MockQueryRequestClient>.Action>!
  
  override func setUp() {
    super.setUp()
    
    store = TestStore(
      initialState: Feature<MockQueryRequestClient>.State(queryType: .set(gameSet, page: 1))
    ) {
      Feature<MockQueryRequestClient>(client: UnsafeSendable(MockQueryRequestClient()))
    }
  }
  
  override func tearDown() {
    store = nil
    super.tearDown()
  }
  
  @MainActor
  func test_sendViewAppeared_shouldSendFetchCards() async {
    await store.send(.viewAppeared)
    await store.receive(.updateCards(ObjectList(model: [magicCard], hasNextPage: true), .set(gameSet, page: 1))) { state in
      state.dataSource = ObjectList(model: [magicCard], hasNextPage: true)
    }
  }
  
  @MainActor
  func test_hasNextPageIsTrue_whenLoadMoreCardsIfNeeded_shouldLoadMore() async {
    let store: TestStore<Feature<MockQueryRequestClient>.State, Feature<MockQueryRequestClient>.Action> = TestStore(
      initialState: Feature.State(
        queryType: .set(gameSet, page: 1),
        dataSource: ObjectList(model: [magicCard], hasNextPage: true)
      )
    ) {
      Feature(client: UnsafeSendable(MockQueryRequestClient()))
    }
    
    await store.send(.loadMoreCardsIfNeeded(currentIndex: 0))
    
    await store.receive(.updateCards(ObjectList(model: [magicCard], hasNextPage: true), .set(gameSet, page: 2))) { state in
      state.dataSource = ObjectList(model: [magicCard, magicCard], hasNextPage: true)
      state.queryType = .set(gameSet, page: 2)
    }
  }
  
  @MainActor
  func test_hasNextPageIsFalse_whenLoadMoreCardsIfNeeded_shouldNotLoadMore() async {
    let store: TestStore<Feature<MockQueryRequestClient>.State, Feature<MockQueryRequestClient>.Action> = TestStore(
      initialState: Feature.State(
        queryType: .set(gameSet, page: 1),
        dataSource: ObjectList(model: [magicCard], hasNextPage: false)
      )
    ) {
      Feature(client: UnsafeSendable(MockQueryRequestClient()))
    }
    
    await store.send(.loadMoreCardsIfNeeded(currentIndex: 0))
  }
}
