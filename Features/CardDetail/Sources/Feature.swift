import ComposableArchitecture
import Foundation
import OSLog
import Networking

@Reducer struct Feature<Client: MagicCardDetailRequestClient> {
  private let client: Client
  
  init(client: Client) {
    self.client = client
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .fetchSet(card):
        return .merge(
          .run { send in
            try await send(
              .updateSetIconURL(.success(client.getSet(of: card).iconURL))
            )
          },
          .run { send in
            try await send(
              .updateVariants(.success(client.getVariants(of: card, page: 0)))
            )
          },
          .run { send in
            try await send(
              .updateRulings(client.getRulings(of: card))
            )
          }
        )
        
      case let .fetchVariants(card):
        return .merge(
          .run { send in
            try await send(
              .updateVariants(.success(client.getVariants(of: card, page: 0)))
            )
          },
          .run { send in
            try await send(
              .updateRulings(client.getRulings(of: card))
            )
          }
        )
        
      case .transformTapped:
        state.content.faceDirection = state.content.faceDirection.toggled()
        return .none
        
      case let .updateRulings(rulings):
        state.content.rulings = rulings
        return .none
        
      case let .updateSetIconURL(value):
        state.content.setIconURL = value
        return .run { [card = state.content.card] send in
          await send(.fetchVariants(card: card))
        }
        
      case let .updateVariants(value):
        state.content.variants = value
        return .none
        
      case let .viewAppeared(action):
        return .run { send in
          await send(action)
        }
      }
    }
    ._printChanges()
  }
}

extension Feature {
  @ObservableState struct State: Equatable, Sendable {
    var content: Content<Client.MagicCardModel>
    let start: Action
    
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
    case transformTapped
    case updateRulings(_ rulings: [MagicCardRuling])
    case updateSetIconURL(_ setIconURL: Result<URL?, FeatureError>)
    case updateVariants(_ variants: Result<[Client.MagicCardModel], FeatureError>)
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
