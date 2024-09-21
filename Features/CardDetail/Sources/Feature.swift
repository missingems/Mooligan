import ComposableArchitecture
import Foundation
import OSLog
import Networking

@Reducer struct Feature<Client: MagicCardDetailRequestClient> {
  private let client: Client
  
  /// Initializes the feature with a network client.
  /// - Parameter client: The client used for fetching card data.
  init(client: Client) {
    self.client = client
  }
  
  /// Defines how the state should be updated based on actions.
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
        return .run { send in
          try await send(.updateSetIconURL(client.getSet(of: card).iconURL))
        } catch: { error, _ in
          os_log(.error, log: .default, "\(error.localizedDescription)")
        }
        
      case let .fetchVariants(card):
        return .run { send in
          try await send(.updateVariants(client.getVariants(of: card, page: 0)))
        } catch: { error, send in
          os_log(.error, log: .default, "\(error.localizedDescription)")
        }
        
      case let .viewAppeared(action):
        return .run {
          await $0(action)
        }
      }
    }
  }
}

extension Feature {
  @ObservableState struct State: Equatable, Sendable {
    var content: Content<Client.MagicCardModel>
    let start: Action
    
    /// Initializes the state based on the entry point and card details.
    /// - Parameters:
    ///   - card: The magic card model to be used.
    ///   - entryPoint: The entry point which determines the initial action and content configuration.
    init(
      card: Client.MagicCardModel,
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
    case fetchSet(card: Client.MagicCardModel)
    case fetchVariants(card: Client.MagicCardModel)
    case updateVariants(_ variants: [Client.MagicCardModel])
    case updateSetIconURL(_ setIconURL: URL?)
    case viewAppeared(initialAction: Action)
  }
}
