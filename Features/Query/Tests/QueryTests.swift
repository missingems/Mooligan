@testable import Query
import ComposableArchitecture
import Networking
import XCTest

private let magicCard = MockMagicCard()
private let gameSet = MockGameSet()

final actor MockQueryRequestClient: MagicCardQueryRequestClient {
  func queryCards(_ query: QueryType) async throws -> ObjectList<[MockMagicCard]> {
    return ObjectList(model: [magicCard], hasNextPage: true)
  }
}

final class QueryTests: XCTestCase {
  private var store: TestStore<Feature<MockQueryRequestClient>.State, Feature<MockQueryRequestClient>.Action>!
  
  override func setUp() {
    super.setUp()
    
    store = TestStore(
      initialState: Feature<MockQueryRequestClient>.State(queryType: .set(gameSet, page: 0))
    ) {
      Feature<MockQueryRequestClient>(client: MockQueryRequestClient())
    }
  }
  
  override func tearDown() {
    store = nil
    super.tearDown()
  }
  
  func test_sendViewAppeared_shouldSendFetchCards() async {
    await store.send(.viewAppeared)
    await store.receive(.fetchCards(.set(gameSet, page: 1)))
    await store.receive(.updateCards(ObjectList(model: [magicCard]))) { state in
      state.dataSource = ObjectList(model: [magicCard], hasNextPage: true)
    }
  }
  
  func test_loadMoreCardsIfNeeded_shouldLoadMore() async {
    await store.send(.loadMoreCardsIfNeeded(currentIndex: 0))
    await store.receive(.fetchCards(.set(gameSet, page: 1)))
    await store.receive(.updateCards(ObjectList(model: [magicCard], hasNextPage: true))) { state in
      state.dataSource = ObjectList(model: [magicCard, magicCard], hasNextPage: true)
    }
  }
}
