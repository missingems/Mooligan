@testable import Query
import ComposableArchitecture
import Networking
import Testing

struct FeatureTests {
  @Test func withPlaceholder_whenViewAppeared_shouldQueryCards_thenUpdateCards() async {
    let store: TestStoreOf<Query.Feature> = await TestStore(
      initialState: Query.Feature.State(mode: .placeholder(numberOfDataSource: <#T##Int#>), queryType: <#T##QueryType#>, selectedCard: <#T##Card?#>)
    ) {
      Browse.Feature()
    }
    
    await store.send(.viewAppeared)
    await store.receive(.updateCards(ObjectList(model: [magicCard], hasNextPage: true), .set(gameSet, page: 1))) { state in
      state.dataSource = ObjectList(model: [magicCard], hasNextPage: true)
    }
  }
  
//  @MainActor
//  func test_hasNextPageIsTrue_whenLoadMoreCardsIfNeeded_shouldLoadMore() async {
//    let store: TestStore<Feature<MockQueryRequestClient>.State, Feature<MockQueryRequestClient>.Action> = TestStore(
//      initialState: Feature.State(
//        queryType: .set(gameSet, page: 1),
//        dataSource: ObjectList(model: [magicCard], hasNextPage: true)
//      )
//    ) {
//      Feature(client: MockQueryRequestClient())
//    }
//    
//    await store.send(.loadMoreCardsIfNeeded(currentIndex: 0))
//    
//    await store.receive(.updateCards(ObjectList(model: [magicCard], hasNextPage: true), .set(gameSet, page: 2))) { state in
//      state.dataSource = ObjectList(model: [magicCard, magicCard], hasNextPage: true)
//      state.queryType = .set(gameSet, page: 2)
//    }
//  }
//  
//  @MainActor
//  func test_hasNextPageIsFalse_whenLoadMoreCardsIfNeeded_shouldNotLoadMore() async {
//    let store: TestStore<Feature<MockQueryRequestClient>.State, Feature<MockQueryRequestClient>.Action> = TestStore(
//      initialState: Feature.State(
//        queryType: .set(gameSet, page: 1),
//        dataSource: ObjectList(model: [magicCard], hasNextPage: false)
//      )
//    ) {
//      Feature(client: MockQueryRequestClient())
//    }
//    
//    await store.send(.loadMoreCardsIfNeeded(currentIndex: 0))
//  }
}
