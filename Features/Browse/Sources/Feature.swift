import ComposableArchitecture
import SwiftUI
import Networking
import ScryfallKit

@Reducer public struct Feature {
  @ObservableState public struct State: Equatable {
    var isLoading: Bool = false
    var selectedSet: MTGSet? = nil
    var sets: IdentifiedArrayOf<MTGSet> = []
    let title = String(localized: "Sets")
  }
  
  public enum Action: Equatable {
    case didSelectSet(index: Int)
    case fetchSets
    case viewAppeared
    case updateSets([MTGSet])
  }
  
  @Dependency(\.gameSetRequestClient) var client
  
  public var body: some ReducerOf<Self> {
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
        state.sets = IdentifiedArrayOf<MTGSet>(uniqueElements: value)
        return .none
      }
    }
  }
  
  public init() {}
}
