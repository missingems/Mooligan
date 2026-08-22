import ComposableArchitecture
import SwiftUI
import Networking
import ScryfallKit

@Reducer public struct BrowseFeature: Sendable {
  @Dependency(\.gameSetRequestClient) var client
  @Dependency(\.continuousClock) var clock
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding(\.query):
        return .run { [query = state.query, sets = state.sets] send in
          try await clock.sleep(for: .milliseconds(300))
          await send(.searchSets(.name(query, sets)))
        }
        .cancellable(id: "queryDebounce", cancelInFlight: true)
        
      case .binding:
        return .none
        
      case let .didSelectSet(value):
        state.selectedSet = value
        return .none
        
      case let .searchSets(query):
        return .run { send in
          let value = try await client.getSets(queryType: query)
          await send(.updateSetSections(sections: value.0, flattened: value.1))
        } catch: { error, send in
          await send(.fetchFailed(error.localizedDescription))
        }.cancellable(id: "searchSets", cancelInFlight: true)
        
      case let .fetchFailed(errorMessage):
        state.mode = .error(errorMessage)
        return .none
        
      case .retry:
        state.mode = .placeholder(.init(uniqueElements: MockGameSetRequestClient.mocksSetSections))
        
        let query = state.query
        let sets = state.sets
        
        return .run { send in
          if query.isEmpty {
            await send(.searchSets(.all))
          } else {
            await send(.searchSets(.name(query, sets)))
          }
        }
        
      case .viewAppeared:
        return if state.mode.isPlaceholder {
          .run { send in
            await send(.searchSets(.all))
          }
        } else {
          .none
        }
        
      case let .updateSetSections(folder, flattened):
        state.sets = flattened
        state.mode = .data(IdentifiedArrayOf(uniqueElements: folder))
        return .none
      }
    }
  }
  
  public init() {}
}

public extension BrowseFeature {
  @ObservableState struct State: Equatable {
    var sets: [MTGSet] = []
    var mode: Mode = .placeholder(.init(uniqueElements: MockGameSetRequestClient.mocksSetSections))
    var selectedSet: MTGSet?
    var query = ""
    var queryPlaceholder = String(localized: "Enter set name...")
    
    public init(selectedSet: MTGSet? = nil) {
      self.selectedSet = selectedSet
    }
  }
  
  enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case didSelectSet(MTGSet)
    case searchSets(GameSetQueryType)
    case fetchFailed(String)
    case retry
    case viewAppeared
    case updateSetSections(sections: [ScryfallClient.SetsSection], flattened: [MTGSet])
  }
}

public extension BrowseFeature.State {
  enum Mode: Equatable {
    case placeholder(IdentifiedArrayOf<ScryfallClient.SetsSection>)
    case data(IdentifiedArrayOf<ScryfallClient.SetsSection>)
    case error(String)
    
    var isPlaceholder: Bool {
      switch self {
      case .placeholder: return true
      case .data, .error: return false
      }
    }
    
    var isScrollable: Bool {
      switch self {
      case .data: return true
      case .placeholder, .error: return false
      }
    }
    
    var data: IdentifiedArrayOf<ScryfallClient.SetsSection> {
      switch self {
      case let .placeholder(value): return value
      case let .data(value): return value
      case .error: return []
      }
    }
  }
}
