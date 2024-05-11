import ComposableArchitecture
import Networking

@Reducer
struct Feature<Client: MagicCardQueryRequestClient> {
  let client: Client
  
  @ObservableState
  struct State: Equatable {
    var queryType: QueryType
    var dataSource = ObjectList<[Client.MagicCardModel]>(model: [])
  }
  
  enum Action: Equatable {
    case fetchCards(QueryType)
    case loadMoreCardsIfNeeded(currentIndex: Int)
    case updateCards(ObjectList<[Client.MagicCardModel]>)
    case viewAppeared
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .fetchCards(queryType):
        state.queryType = queryType
        return .run { send in
          await send(.updateCards(try await client.queryCards(queryType)))
        }
        
      case let .loadMoreCardsIfNeeded(currentIndex):
        let queryType = state.queryType
        
        if currentIndex == state.dataSource.model.count - 1, state.dataSource.hasNextPage {
          return .run { send in
            await send(.fetchCards(queryType.next()))
          }
        } else {
          return .none
        }
      
      case let .updateCards(value):
        state.dataSource.model.append(contentsOf: value.model)
        state.dataSource.hasNextPage = value.hasNextPage
        return .none
        
      case .viewAppeared:
        let queryType = state.queryType
        
        return .run { send in
          await send(.fetchCards(queryType))
        }
      }
    }
  }
}
