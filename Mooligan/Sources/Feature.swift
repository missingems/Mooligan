import ComposableArchitecture

@Reducer struct Feature<Client: GameSetRequestClient> {
  let client: Client
  
  @ObservableState struct State: Equatable {
  }
  
  enum Action: Equatable {
    case didSelectSet(index: Int)
    case fetchSets
    case viewAppeared
    case updateSets([Client.GameSetModel])
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didSelectSet(index):
        return .none
        
      case .fetchSets:
        state.isLoading = true
        
        return .run { send in
          try await send(.updateSets(client.getAllSets()))
        }
        
      case .viewAppeared:
        return if state.sets.isEmpty {
          .run { send in
            await send(.fetchSets)
          }
        } else {
          .none
        }
        
      case let .updateSets(value):
        state.isLoading = false
        state.sets = IdentifiedArrayOf<Client.GameSetModel>(uniqueElements: value)
        return .none
      }
    }
  }
}
