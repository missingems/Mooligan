@testable import CardDetail
import ComposableArchitecture
@testable import Networking
import XCTest

final class FeatureTests: XCTestCase {
  typealias Client = Networking.TestMagicCardDetailRequestClient
  private var store: TestStore<Feature<Client>.State, Feature<Client>.Action>!
  
  override func setUp() {
    super.setUp()
    
    store = TestStore(
      initialState: Feature<Client>.State(card: <#T##Card#>, entryPoint: .query),
      reducer: {
        Feature<Client>(client: Client())
      }
    )
  }
  
  override func tearDown() {
    store = nil
    super.tearDown()
  }
  
  func test_whenViewAppeared_shouldSendStart() {
    
  }
  
  func test_whenFetchVariants_shhouldSendUpdateVariants() {
    
  }
  
  func test_whenFetchSets_shhouldSendUpdateSetIconURL() {
    
  }
  
  func test_whenUpdateIconURL_shouldUpdateState() {
    
  }
}
