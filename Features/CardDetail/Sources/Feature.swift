import ComposableArchitecture
import SwiftUI
import Networking

@Reducer
struct Feature {
  
  @ObservableState
  struct State: Equatable {
  }
  
  enum Action: Equatable {
    case loadCardDetail
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .loadCardDetail:
        return .none
      }
    }
    ._printChanges(.actionLabels)
  }
}
