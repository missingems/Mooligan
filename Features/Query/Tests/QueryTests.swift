@testable import Query
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

struct FeatureTests {
  @Test func withPlaceholder_withQueryTypeAsSet_whenViewAppeared_shouldQueryCards_thenUpdateCards() async {
    let store: TestStoreOf<Query.Feature> = await TestStore(
      initialState: Query.Feature.State(
        mode: .placeholder(numberOfDataSource: 10),
        queryType: .set(MockGameSetRequestClient.mockSets[0], page: 1),
        selectedCard: nil
      )
    ) {
      Query.Feature()
    }
    
    await store.send(.viewAppeared)
    await store.receive(
      .updateCards(
        [
          .mock()
        ],
        hasNextPage: false,
        queryType: .set(MockGameSetRequestClient.mockSets[0], page: 1)
      )
    ) { state in
      state.mode = .data(.init(cards: [.mock()], hasNextPage: false))
    }
  }
  
  @Test func whenDidSelectCard_shouldUpdateCard() async {
    let store: TestStoreOf<Query.Feature> = await TestStore(
      initialState: Query.Feature.State(
        mode: .placeholder(numberOfDataSource: 10),
        queryType: .set(MockGameSetRequestClient.mockSets[0], page: 1),
        selectedCard: nil
      )
    ) {
      Query.Feature()
    }
    
    await store.send(.didSelectCard(.mock())) { state in
      state.selectedCard = .mock()
    }
  }
  
  @Test func withHasNextPage_whenLoadMoreCardsIfNeeded_shouldUpdateCards() async {
    let store: TestStoreOf<Query.Feature> = await TestStore(
      initialState: Query.Feature.State(
        mode: .data(.init(cards: [.mock(id: UUID(uuidString: "1121E1F8-C36C-495A-93FC-0C247A3E6E5F"))], hasNextPage: true)),
        queryType: .set(MockGameSetRequestClient.mockSets[0], page: 1),
        selectedCard: nil
      )
    ) {
      Query.Feature()
    } withDependencies: { value in
      value.cardQueryRequestClient = MockCardQueryRequestClient(
        expectedResponse: ObjectList(
          data: [.mock(id: UUID(uuidString: "112111F8-C36C-495A-93FC-0C247A3E6E5F"))],
          hasMore: false,
          nextPage: "1",
          totalCards: 10,
          warnings: nil
        )
      )
    }
    
    await store.send(.loadMoreCardsIfNeeded(displayingIndex: 0))
    await store.receive(
      .updateCards(
        [
          .mock(id: UUID(uuidString: "112111F8-C36C-495A-93FC-0C247A3E6E5F"))
        ],
        hasNextPage: false,
        queryType: .set(MockGameSetRequestClient.mockSets[0], page: 2)
      )
    ) { state in
      state.mode = .data(
        .init(
          cards: [
            .mock(id: UUID(uuidString: "1121E1F8-C36C-495A-93FC-0C247A3E6E5F")),
            .mock(id: UUID(uuidString: "112111F8-C36C-495A-93FC-0C247A3E6E5F"))
          ],
          hasNextPage: false
        )
      )
      
      state.queryType = .set(MockGameSetRequestClient.mockSets[0], page: 2)
    }
  }
  
  @Test func withoutHasNextPage_whenLoadMoreCardsIfNeeded_shouldNotUpdateCards() async {
    let store: TestStoreOf<Query.Feature> = await TestStore(
      initialState: Query.Feature.State(
        mode: .data(.init(cards: [.mock(id: UUID(uuidString: "1121E1F8-C36C-495A-93FC-0C247A3E6E5F"))], hasNextPage: false)),
        queryType: .set(MockGameSetRequestClient.mockSets[0], page: 1),
        selectedCard: nil
      )
    ) {
      Query.Feature()
    } withDependencies: { value in
      value.cardQueryRequestClient = MockCardQueryRequestClient(
        expectedResponse: ObjectList(
          data: [],
          hasMore: false,
          nextPage: "1",
          totalCards: 1,
          warnings: nil
        )
      )
    }
    
    await store.send(.loadMoreCardsIfNeeded(displayingIndex: 0))
  }
}

