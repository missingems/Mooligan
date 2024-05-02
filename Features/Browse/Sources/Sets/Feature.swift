import ComposableArchitecture
import Networking

@Reducer
struct Feature<Client: BrowseRequestClient> {
  let client: Client
  
  @ObservableState
  struct State: Equatable {
    var isLoading: Bool = false
    var selectedSet: Client.Model? = nil
    var sets: [Client.Model] = []
    var title = String(localized: "Sets")
  }
  
  enum Action: Equatable {
    case didSelectSet(Client.Model)
    case fetchSets
    case viewAppeared
    case updateSets([Client.Model])
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didSelectSet(set):
        state.selectedSet = set
        return .none
        
      case .fetchSets:
        state.isLoading = true
        
        return .run { send in
          let objectList = try await client.getAllSets()
          await send(.updateSets(objectList))
        }
        
      case .viewAppeared:
        return .run { send in
          await send(.fetchSets)
        }
        
      case let .updateSets(value):
        state.isLoading = false
        state.sets = value
        return .none
      }
    }
    ._printChanges(.actionLabels)
  }
}
