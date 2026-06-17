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
          
          await send(
            .updateSetSections(sections: value.0, flattened: value.1)
          )
        }.cancellable(id: "searchSets", cancelInFlight: true)
        
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
    case viewAppeared
    case updateSetSections(sections: [ScryfallClient.SetsSection], flattened: [MTGSet])
  }
}

public extension BrowseFeature.State {
  enum Mode: Equatable {
    case placeholder(IdentifiedArrayOf<ScryfallClient.SetsSection>)
    case data(IdentifiedArrayOf<ScryfallClient.SetsSection>)
    
    var isPlaceholder: Bool {
      switch self {
      case .placeholder:
        return true
        
      case .data:
        return false
      }
    }
    
    var isScrollable: Bool {
      switch self {
      case .placeholder:
        return false
        
      case .data:
        return true
      }
    }
    
    var data: IdentifiedArrayOf<ScryfallClient.SetsSection> {
      switch self {
      case let .placeholder(value):
        return value
        
      case let .data(value):
        return value
      }
    }
  }
}
