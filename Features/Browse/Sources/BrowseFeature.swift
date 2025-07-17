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
        }.debounce(id: "queryDebounce", for: .milliseconds(300), scheduler: DispatchQueue.main)
        
      case .binding:
        return .none
        
      case let .didSelectSet(value):
        state.selectedSet = value
        return .none
        
      case .fetchSets:
        return .run { send in
          let value = try await client.getSets(queryType: .all)
          
          await send(
            .updateSetSections(sections: value.0, flattened: value.1),
            animation: .default
          )
        }.cancellable(id: "fetchSets", cancelInFlight: true)
        
      case let .searchSets(query):
        return .run { [sets = state.sets] send in
          let value = try await client.getSets(queryType: .name(query, sets))
          
          await send(
            .updateSetSections(sections: value.0, flattened: value.1),
            animation: .default
          )
        }.cancellable(id: "searchSets", cancelInFlight: true)
        
      case .viewAppeared:
        return if state.sections.isEmpty {
          .run { send in
            await send(.fetchSets(.all))
          }
        } else {
          .none
        }
        
      case let .updateSetSections(folder, flattened):
        state.sets = flattened
        state.sections = IdentifiedArrayOf(uniqueElements: folder)
        return .none
      }
    }
  }
  
  public init() {}
}

public extension BrowseFeature {
  @ObservableState struct State: Equatable {
    var selectedSet: MTGSet?
    var sets: [MTGSet] = []
    var query = ""
    var queryPlaceholder = String(localized: "Enter set name...")
    var sections: IdentifiedArrayOf<ScryfallClient.SetsSection> = []
    
    public init(selectedSet: MTGSet?) {
      self.selectedSet = selectedSet
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case didSelectSet(MTGSet)
    case fetchSets(GameSetQueryType)
    case searchSets(String)
    case viewAppeared
    case updateSetSections(sections: [ScryfallClient.SetsSection], flattened: [MTGSet])
  }
}

public extension BrowseFeature.State {
  enum Mode: Equatable {
    case placeholder
    case data
    case loading
    
    var isPlaceholder: Bool {
      switch self {
      case .placeholder:
        return true
        
      case .data:
        return false
        
      case .loading:
        return false
      }
    }
    
    var isScrollable: Bool {
      switch self {
      case .placeholder:
        return false
        
      case .data:
        return true
        
      case .loading:
        return false
      }
    }
  }
}
