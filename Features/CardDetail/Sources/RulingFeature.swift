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
        state.rulings = rulings
        
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
    let card: Client.MagicCardModel
    var rulings: [MagicCardRuling] = []
    let title: String
  }
  
  enum Action: Equatable {
    case fetchRulings
    case updateRulings([MagicCardRuling])
  }
}
