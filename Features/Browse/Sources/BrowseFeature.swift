import ComposableArchitecture
import SwiftUI
import Networking
import ScryfallKit

@Reducer public struct BrowseFeature {
  @Dependency(\.gameSetRequestClient) var client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .binding(\.query):
        return .run { [state] send in
          await send(.searchSets(state.query))
        }.cancellable(id: "searchSets", cancelInFlight: true)
        
      case .binding:
        return .none
        
      case let .didSelectSet(value):
        state.selectedSet = value
        return .none
        
      case .fetchSets:
        return .run { send in
          try await send(.updateSets(client.getAllSets()))
        }
        
      case let .searchSets(query):
        return .run { send in
          let sets = try await client.getSets(queryType: .name(query))
          await send(.updateSets(sets), animation: .default)
        }
        
      case .viewAppeared:
        return if state.sets.isEmpty {
          .run { send in
            await send(.fetchSets(.all))
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
    var query = ""
    var queryPlaceholder = String(localized: "Enter set name...")
    
    public init(
      selectedSet: MTGSet?,
      sets: IdentifiedArrayOf<MTGSet>
    ) {
      self.selectedSet = selectedSet
      self.sets = sets
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case didSelectSet(MTGSet)
    case fetchSets(GameSetQueryType)
    case searchSets(String)
    case viewAppeared
    case updateSets([MTGSet])
  }
}
