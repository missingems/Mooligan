import ComposableArchitecture
import Networking

@Reducer
struct Feature<Client: MagicCardQueryRequestClient> {
  let client: Client
  
  @ObservableState
  struct State: Equatable {
    let queryType: QueryType
    var cards: [Client.MagicCardModel] = []
  }
  
  enum Action: Equatable {
    case fetchCards
    case updateCards([Client.MagicCardModel])
    case viewAppeared
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .fetchCards:
        let queryType = state.queryType
        
        return .run { send in
          await send(
            .updateCards(
              try await client.queryCards(queryType)
            )
          )
        }
      
      case let .updateCards(value):
        state.cards = value
        return .none
        
      case .viewAppeared:
        return .run { send in
          await send(.fetchCards)
        }
      }
    }
  }
}
