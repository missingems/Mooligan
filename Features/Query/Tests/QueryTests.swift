@testable import Query
import ComposableArchitecture
import Networking
import XCTest

let magicCard = MockMagicCard()

final actor MockQueryRequestClient: MagicCardQueryRequestClient {
  typealias MagicCardModel = MockMagicCard
  
  func queryCards(_ query: Networking.QueryType) async throws -> [MockMagicCard] {
    return [magicCard]
  }
}

final class QueryTests: XCTestCase {
  private var store: TestStore<Feature<MockQueryRequestClient>.State, Feature<MockQueryRequestClient>.Action>!
  
  override func setUp() {
    super.setUp()
    
    store = TestStore(
      initialState: Feature<MockQueryRequestClient>.State(queryType: .set(MockGameSet(), page: 0))
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
    await store.receive(.fetchCards)
    await store.receive(.updateCards([magicCard])) { state in
      state.cards = [magicCard]
    }
  }
}
