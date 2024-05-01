import ComposableArchitecture
import Networking

@Reducer
public struct Feature<Client: BrowseRequestClient> {
  private let client: Client
  
  @ObservableState
  public struct State: Equatable {
    var isLoading: Bool = false
    var selectedSet: Client.Model? = nil
    var sets: [Client.Model] = []
    
    public init() {}
  }
  
  public enum Action: Equatable {
    case didSelectSet(Client.Model)
    case fetchSets
    case viewAppeared
    case updateSets([Client.Model])
  }
  
  public var body: some ReducerOf<Self> {
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
  
  public init(client: Client) {
    self.client = client
  }
}
