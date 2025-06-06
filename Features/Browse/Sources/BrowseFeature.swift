import ComposableArchitecture
import SwiftUI
import Networking
import ScryfallKit

@Reducer public struct BrowseFeature {
  @Dependency(\.gameSetRequestClient) var client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didSelectSet(value):
        state.selectedSet = value
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
        state.sets = IdentifiedArrayOf(uniqueElements: value)
        return .none
      }
    }
  }
  
  public init() {}
}

public extension BrowseFeature {
  @ObservableState struct State: Equatable {
    var selectedSet: MTGSet?
    var sets: IdentifiedArrayOf<MTGSet>
    
    public init(
      selectedSet: MTGSet?,
      sets: IdentifiedArrayOf<MTGSet>
    ) {
      self.selectedSet = selectedSet
      self.sets = sets
    }
  }
  
  enum Action: Equatable {
    case didSelectSet(MTGSet)
    case fetchSets
    case viewAppeared
    case updateSets([MTGSet])
  }
}
