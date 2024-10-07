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
      case let .fetchSet(card):
        return .run { send in
          try await send(.updateSetIconURL(.success(client.getSet(of: card).iconURL)))
          await send(.fetchVariants(card: card))
        } catch: { error, send in
          await send(
            .updateSetIconURL(
              .failure(.failedToFetchSetIconURL(errorMessage: error.localizedDescription))
            )
          )
        }
        
      case let .fetchVariants(card):
        return .run { send in
          try await send(
            .updateVariants(.success(client.getVariants(of: card, page: 0)))
          )
        } catch: { error, send in
          await send(
            .updateVariants(
              .failure(.failedToFetchVariants(errorMessage: error.localizedDescription))
            )
          )
        }
        
      case let .updateVariants(value):
        state.content.variants = value
        return .none
        
      case let .updateSetIconURL(value):
        state.content.setIconURL = value
        return .none
        
      case let .viewAppeared(action):
        return .run { send in
          await send(action)
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
    case updateVariants(_ variants: Result<[Client.MagicCardModel], FeatureError>)
    case updateSetIconURL(_ setIconURL: Result<URL?, FeatureError>)
    case viewAppeared(initialAction: Action)
  }
}

enum FeatureError: Error, Sendable, Equatable {
  case failedToFetchVariants(errorMessage: String)
  case failedToFetchSetIconURL(errorMessage: String)
  
  var localizedDescription: String {
    return switch self {
    case let .failedToFetchVariants(value): value
    case let .failedToFetchSetIconURL(value): value
    }
  }
}
