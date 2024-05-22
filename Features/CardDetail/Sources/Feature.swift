import ComposableArchitecture
import Networking

@Reducer
struct Feature<Client: MagicCardDetailRequestClient> {
  let client: Client
  
  @ObservableState
  struct State: Equatable {
    let card: Client.MagicCardModel
    let page: Int = 0
    var variants: [Client.MagicCardModel] = []
  }
  
  enum Action: Equatable {
    case loadVariants
    case updateVariants([Client.MagicCardModel])
    case viewAppeared
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .loadVariants:
        let card = state.card
        let page = state.page
        
        return .run { send in
          await send(
            .updateVariants(
              try await client.getVariants(
                of: card,
                page: page
              )
            )
          )
        }
        
      case let .updateVariants(value):
        state.variants = value
        return .none
        
      case .viewAppeared:
        return .run { send in
          await send(.loadVariants)
        }
      }
    }
    ._printChanges(.actionLabels)
  }
}
