import ComposableArchitecture
import Foundation
import OSLog
import Networking

@Reducer struct CardDetailFeature<Client: MagicCardDetailRequestClient> {
  private let client: Client
  
  init(client: Client) {
    self.client = client
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
        
      case let .fetchAdditionalInformation(card):
        return .merge(
          [
            .run(
              priority: .background,
              operation: { [state] send in
                if let url = try state.content.setIconURL.get() {
                  await send(.updateSetIconURL(.success(url)))
                } else {
                  try await send(.updateSetIconURL(.success(client.getSet(of: card).iconURL)))
                }
              }, catch: { error, send in
                print(error)
              }
            ),
            .run(
              priority: .background,
              operation: { send in
                try await send(.updateVariants(.success(client.getVariants(of: card, page: 0))))
              }, catch: { error, send in
                await send(.updateVariants(.success([card])))
              }
            ),
            .run(
              priority: .background,
              operation: { send in
                try await send(.updateRulings(client.getRulings(of: card)))
              }, catch: { error, send in
                await send(.updateRulings([]))
              }
            )
          ]
        )
        .cancellable(id: "\(action)", cancelInFlight: true)
        
      case .transformTapped:
        state.isFlipped.toggle()
        return .none
        
      case let .updateRulings(rulings):
        state.content.rulings = rulings
        return .none
        
      case let .updateSetIconURL(value):
        state.content.setIconURL = value
        return .none
        
      case let .updateVariants(value):
        state.content.variants = value
        return .none
        
      case let .viewAppeared(action):
        return .run { send in
          await send(action)
        }
      }
    }
  }
}

extension CardDetailFeature {
  @ObservableState struct State: Equatable, Identifiable {
    let id: UUID
    var content: Content<Client.MagicCardModel>
    let start: Action
    var isFlipped: Bool = false {
      didSet {
        content.faceDirection = content.faceDirection.toggled()
      }
    }
    
    init(
      card: Client.MagicCardModel,
      entryPoint: EntryPoint<Client>
    ) {
      self.id = card.id
      
      switch entryPoint {
      case .query:
        content = Content(card: card, setIconURL: nil)
        
      case let .set(value):
        content = Content(card: card, setIconURL: value.iconURL)
      }
      
      start = .fetchAdditionalInformation(card: card)
    }
  }
  
  indirect enum Action: Equatable, Sendable, BindableAction {
    case binding(BindingAction<State>)
    case fetchAdditionalInformation(card: Client.MagicCardModel)
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
