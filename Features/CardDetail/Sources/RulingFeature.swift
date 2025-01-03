import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit

@Reducer public struct RulingFeature {
  @Dependency(\.cardDetailRequestClient) var client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .fetchRulings:
        return .run { [card = state.card] send in
          let rulings = try await client.getRulings(of: card)
          await send(.updateRulings(rulings))
        }
        
      case let .updateRulings(rulings):
        state.mode = .loaded(rulings)
        return .none
        
      case .dismissTapped:
        return .none
      }
    }
  }
}

public extension RulingFeature {
  @ObservableState struct State: Equatable {
    enum Mode: Equatable {
      case loading
      case loaded([MagicCardRuling])
    }
    
    let card: Card
    let title: String
    var mode: Mode = .loading
    
    var emptyStateTitle: String {
      return "No Results for \"\(card.name)\""
    }
    
    var emptyStateDescription: String? {
      if let url = card.getGathererURLString() {
        return "Look up \(url) for more information."
      } else {
        return nil
      }
    }
  }
  
  enum Action: Equatable {
    case dismissTapped
    case fetchRulings
    case updateRulings([MagicCardRuling])
  }
}
