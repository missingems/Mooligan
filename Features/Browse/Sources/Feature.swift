import ComposableArchitecture
import SwiftUI
import Networking
import ScryfallKit

@Reducer public struct Feature {
  @Dependency(\.gameSetRequestClient) var client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didSelectSet:
        return .none
        
      case .fetchSets:
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
        state.sets = IdentifiedArrayOf<MTGSet>(uniqueElements: value)
        return .none
      }
    }
  }
  
  public init() {}
}

public extension Feature {
  @ObservableState struct State: Equatable {
    var selectedSet: MTGSet?
    var sets: IdentifiedArrayOf<MTGSet>
    let title: String
    
    public init(
      selectedSet: MTGSet?,
      sets: IdentifiedArrayOf<MTGSet>
    ) {
      self.selectedSet = selectedSet
      self.sets = sets
      title = String(localized: "Sets")
    }
  }
  
  enum Action: Equatable {
    case didSelectSet(index: Int)
    case fetchSets
    case viewAppeared
    case updateSets([MTGSet])
  }
}
