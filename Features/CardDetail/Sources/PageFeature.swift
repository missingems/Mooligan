import ComposableArchitecture
import Foundation
import Networking

@Reducer public struct PageFeature<Client: MagicCardDetailRequestClient> {
  let client: Client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .fetchCards:
        return .none
        
      case .viewAppeared:
        return .run { send in
          await send(.fetchCards)
        }
      }
    }
  }
  
  public init(client: Client) {
    self.client = client
  }
}

public extension PageFeature {
  @ObservableState struct State: Equatable, Sendable {
    var shouldDisplayNavigationBar = false
    var cards: [Client.MagicCardModel] = []
    
    public init(cards: [Client.MagicCardModel]) {
      self.cards = cards
    }
  }
  
  enum Action: Equatable, Sendable {
    case fetchCards
    case viewAppeared
  }
}

@Reducer
struct CounterFeature {
  struct State: Equatable, Identifiable {
    let id = UUID()
  }
  enum Action {
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // Core logic of the app feature
      return .none
    }
  }
}

@Reducer
struct AppFeature {
  struct State: Equatable {
    var tabs: IdentifiedArrayOf<CounterFeature.State> = []
  }
  enum Action {
    case tab(CounterFeature.Action)
  }
  var body: some ReducerOf<Self> {
    Scope(state: \.tabs, action: \.tab) {
//      CounterFeature()
//      CounterFeature().forEach(\.id, action: .`self`)
    }
    
//    Scope(state: \.tab1, action: \.tab1) {
//      CounterFeature()
//    }
    Reduce { state, action in
      // Core logic of the app feature
      return .none
    }
  }
}
