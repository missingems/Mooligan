import ComposableArchitecture
import Foundation
import Networking

@Reducer
struct Feature<Client: MagicCardDetailRequestClient> {
  typealias Card = Client.MagicCardModel
  let client: Client
  
  @ObservableState
  struct State {
    let card: Card
    var configuration: ContentConfiguration<Card>?
    var prints: [Card] = []
    
    init(card: Card) {
      self.card = card
    }
  }
  
  enum Action {
    case viewAppeared
    case showPrints([Card])
    case updateConfiguration(ContentConfiguration<Card>)
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .updateConfiguration(configuration):
        state.configuration = configuration
        return .none
        
      case .viewAppeared:
        let card = state.card
        
        return .run { send in
          try await send(.showPrints(client.getVariants(of: card, page: 0)))
        }
        
      case let .showPrints(cards):
        print(cards)
        return .none
      }
    }
  }
}

