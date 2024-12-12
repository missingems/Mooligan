import ComposableArchitecture
import Foundation
import Networking

@Reducer struct RulingFeature<Client: MagicCardDetailRequestClient> {
  let client: Client
  let card: Client.MagicCardModel
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .fetchRulings:
        return .run { [card] send in
          try await send(.updateRulings(client.getRulings(of: card)))
        }
        
      case let .updateRulings(rulings):
        state.rulings = rulings
        return .none
      }
    }
  }
  
  init(
    client: Client,
    card: Client.MagicCardModel
  ) {
    self.client = client
    self.card = card
  }
}

extension RulingFeature {
  @ObservableState struct State: Equatable {
    var rulings: [MagicCardRuling]
  }
  
  enum Action: Equatable {
    case fetchRulings
    case updateRulings([MagicCardRuling])
  }
}
