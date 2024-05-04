import ComposableArchitecture
import Networking

@Reducer
struct Feature {
  enum QueryType {
    case set
  }
  
  @ObservableState
  struct State: Equatable {
    let queryType: QueryType
  }
  
  enum Action: Equatable {
    case fetchCards
    case updateCards
    case viewAppeared
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .fetchCards:
        return .none
      
      case .updateCards:
        return .none
        
      case .viewAppeared:
        return .none
      }
    }
  }
}
