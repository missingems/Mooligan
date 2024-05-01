import ComposableArchitecture
import Networking

@Reducer
public struct Feature<Client: BrowseRequestClient> {
  private let client: Client
  
  @ObservableState
  public struct State: Equatable {
    var isLoading: Bool
    var sets: [Client.Model]
    
    public init(
      isLoading: Bool = false,
      sets: [Client.Model] = []
    ) {
      self.isLoading = isLoading
      self.sets = sets
    }
  }
  
  public enum Action: Equatable {
    case fetchSets
    case viewAppeared
    case updateSets([Client.Model])
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
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

