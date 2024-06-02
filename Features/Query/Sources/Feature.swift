import ComposableArchitecture
import Networking

@Reducer
struct Feature<Client: MagicCardQueryRequestClient> {
  let client: Client
  
  enum Cancellables: Hashable {
    case queryCards(page: Int)
  }
  
  @ObservableState
  struct State: Equatable {
    var queryType: QueryType
    var dataSource = ObjectList<[Client.MagicCardModel]>(model: [])
  }
  
  enum Action: Equatable {
    case fetchCards(QueryType)
    case loadMoreCardsIfNeeded(currentIndex: Int)
    case updateCards(ObjectList<[Client.MagicCardModel]>, QueryType)
    case viewAppeared
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .fetchCards(queryType):
        return .run { send in
          do {
            let cards = try await client.queryCards(queryType)
            await send(.updateCards(cards, queryType))
          } catch {
            print(error.localizedDescription)
          }
        }
        
      case let .loadMoreCardsIfNeeded(currentIndex):
        if currentIndex == state.dataSource.model.count - 1, state.dataSource.hasNextPage {
          let nextPage = state.queryType.next()
          
          return .run { send in
              await send(.fetchCards(nextPage))
            }
            .cancellable(id: Cancellables.queryCards(page: nextPage.page), cancelInFlight: false)
        } else {
          return .none
        }
      
      case let .updateCards(value, queryType):
        state.queryType = queryType
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
    ._printChanges(.actionLabels)
  }
}
