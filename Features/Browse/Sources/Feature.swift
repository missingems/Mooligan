import ComposableArchitecture
import Networking

@Reducer
public struct Feature {
  private var request = BrowseRequest(.scryfall)
  
  @ObservableState
  public struct State: Equatable {
    public static func == (lhs: Feature.State, rhs: Feature.State) -> Bool {
      return true
    }
    
    var isLoading: Bool
    var gameSetObjectList: ObjectList<any GameSet>
    
    public init(
      isLoading: Bool = false,
      gameSetObjectList: ObjectList<any GameSet> = ObjectList<any GameSet>()
    ) {
      self.isLoading = isLoading
      self.gameSetObjectList = gameSetObjectList
    }
  }
  
  public enum Action: Equatable {
    case fetchSets
    case viewAppeared
    case updateSets(ObjectList<any GameSet>)
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .fetchSets:
        return .run { send in
          let objectList = ObjectList(sets: try await request.client.getAllSets())
          
          await send(.updateSets(objectList))
        }
        
      case .viewAppeared:
        return .run { send in
          await send(.fetchSets)
        }
        
      case let .updateSets(value):
        state.gameSetObjectList = value
        return .none
      }
    }
    ._printChanges(.actionLabels)
  }
  
  public init(
    request: BrowseRequest = BrowseRequest(.scryfall)
  ) {
    self.request = request
  }
}

