import ComposableArchitecture
import Foundation
import Networking

@Reducer struct RulingFeature<Client: MagicCardDetailRequestClient> {
  let client: Client
  
  var body: some ReducerOf<Self> {
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
      }
    }
  }
  
  init(
    client: Client
  ) {
    self.client = client
  }
}

extension RulingFeature {
  @ObservableState struct State: Equatable {
    enum Mode: Equatable {
      case loading
      case loaded([MagicCardRuling])
    }
    
    let card: Client.MagicCardModel
    let title: String
    var mode: Mode = .loading
    
    var emptyStateTitle: String {
      return "No Results for \(card.getName())"
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
    case fetchRulings
    case updateRulings([MagicCardRuling])
  }
}
