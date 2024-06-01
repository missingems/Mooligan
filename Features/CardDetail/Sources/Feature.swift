import ComposableArchitecture
import Foundation
import Networking

@Reducer
struct Feature<Client: MagicCardDetailRequestClient> {
  typealias Card = Client.MagicCardModel
  private let client: Client
  
  @ObservableState
  struct State {
    var content: Content<Card>
    
    init(card: Card) {
      content = Content(card: card)
    }
  }
  
  enum Action {
    case start
    case update(variants: [Card])
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .update(variants):
        state.content.variants = variants
        return .none
        
      case .start:
        let card = state.content.card
        
        return .run { send in
          try await send(.update(variants: client.getVariants(of: card, page: 0)))
        }
      }
    }
  }
}
