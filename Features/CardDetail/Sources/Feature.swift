import ComposableArchitecture
import Foundation
import Networking

@Reducer
struct Feature<Client: MagicCardDetailRequestClient> {
  typealias Card = Client.MagicCardModel
  
  @ObservableState
  struct State: Equatable, Sendable {
    var content: Content<Card>
    let start: Action
    
    init(
      card: Card,
      entryPoint: EntryPoint<Client>
    ) {
      switch entryPoint {
      case .query:
        content = Content(card: card, setIconURL: nil)
        start = .fetchSet(card: card)
        
      case let .set(value):
        content = Content(card: card, setIconURL: value.iconURL)
        start = .fetchVariants(card: card)
      }
    }
  }
  
  indirect enum Action: Equatable, Sendable {
    case fetchSet(card: Card)
    case fetchVariants(card: Card)
    case updateVariants(_ variants: [Card])
    case updateSetIconURL(_ setIconURL: URL?)
    case viewAppeared(initialAction: Action)
  }
  
  private let client: Client
  
  init(client: Client) {
    self.client = client
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .updateVariants(value):
        state.content.variants = value
        return .none
        
      case let .updateSetIconURL(value):
        state.content.setIconURL = value
        return .none
        
      case let .fetchSet(card):
        return .run { [client] in
          try await $0(.updateSetIconURL(client.getSet(of: card).iconURL))
        }
        
      case let .fetchVariants(card):
        return .run { [client] in
          try await $0(.updateVariants(client.getVariants(of: card, page: 0)))
        }
        
      case let .viewAppeared(action):
        return .run { await $0(action) }
      }
    }
  }
}
