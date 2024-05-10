@testable import Query
import ComposableArchitecture
import Networking
import XCTest

final actor MockQueryRequestClient: MagicCardQueryRequestClient {
  typealias MagicCardModel = MockMagicCard
  
  func queryCards(_ query: Networking.QueryType) async throws -> [MockMagicCard] {
    return [MockMagicCard()]
  }
}

final class QueryTests: XCTestCase {
  private var store: TestStore<Feature<MockQueryRequestClient>.State, Feature<MockQueryRequestClient>.Action>!
  
  override func setUp() {
    super.setUp()
    
    store = TestStore(
      initialState: Feature<MockQueryRequestClient>.State(queryType: .set(<#T##any GameSet#>, page: 0))
    ) {
      Feature<MockQueryRequestClient>(client: MockQueryRequestClient())
    }
  }
  
  override func tearDown() {
    store = nil
    super.tearDown()
  }
}
