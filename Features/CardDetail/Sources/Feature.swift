import ComposableArchitecture
import Foundation
import Networking

@Reducer
struct Feature<Client: MagicCardDetailRequestClient> {
  typealias Card = Client.MagicCardModel
  
  @ObservableState
  struct State {
    var content: Content<Card>
    let start: Action
    
    init(
      card: Card,
      entryPoint: EntryPoint<Client>
    ) {
      switch entryPoint {
      case .query:
        content = Content(card: card, setIconURL: nil)
        start = .fetchSet
        
      case let .set(value):
        content = Content(card: card, setIconURL: value.iconURL)
        start = .fetchVariants
      }
    }
  }
  
  enum Action {
    case fetchSet
    case fetchVariants
    case viewAppeared
    case updateVariants(_ variants: [Card])
    case updateSetIconURL(_ setIconURL: URL)
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
        
      case .fetchSet:
        let card = state.content.card
        return .run { send in
          guard let url = try await client.getSet(of: card).iconURL else { return }
          await send(.updateSetIconURL(url))
        }
        
      case .fetchVariants:
        let card = state.content.card
        return .run { try await $0(.updateVariants(await client.getVariants(of: card, page: 0))) }
        
      case .viewAppeared:
        let start = state.start
        return .run { await $0(start) }
      }
    }
  }
}
