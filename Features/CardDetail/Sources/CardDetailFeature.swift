import ComposableArchitecture
import DesignComponents
import Foundation
import OSLog
import Networking

@Reducer struct CardDetailFeature<Client: MagicCardDetailRequestClient> {
  private let client: Client
  
  init(client: Client) {
    self.client = client
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .dismissRulingsTapped:
        state.showRulings = nil
        return .none
        
      case let .fetchAdditionalInformation(card):
        return .merge(
          [
            .run(
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
              operation: { send in
                try await send(.updateVariants(.success(client.getVariants(of: card, page: 0))))
              }, catch: { error, send in
                await send(.updateVariants(.success([card])))
              }
            ),
          ]
        )
        .cancellable(id: "\(action)", cancelInFlight: true)
        
      case .descriptionCallToActionTapped:
        switch state.content.selectedMode {
        case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName):
          state.content.selectedMode = .transformable(
            direction: direction.toggled(),
            frontImageURL: frontImageURL,
            backImageURL: backImageURL,
            callToActionIconName: callToActionIconName
          )
          
          state.content.faceDirection = state.content.faceDirection.toggled()
          
        case let .flippable(direction, displayingImageURL, callToActionIconName):
          state.content.selectedMode = .flippable(
            direction: direction.toggled(),
            displayingImageURL: displayingImageURL,
            callToActionIconName: callToActionIconName
          )
          
          state.content.faceDirection = state.content.faceDirection.toggled()
          
        case let .single(displayingImageURL):
          break
          
        default:
          break
        }

        return .none
        
      case let .updateSetIconURL(value):
        state.content.setIconURL = value
        return .none
        
      case let .updateVariants(value):
        if let cards = try? value.get() {
          state.content.variants = IdentifiedArray(uniqueElements: cards)
        }
        
        return .none
        
      case let .viewAppeared(action):
        return .run { send in
          await send(action)
        }
        
      case .viewRulingsTapped:
        state.showRulings = RulingFeature.State(
          card: state.content.card,
          title: "Rulings"
        )
        
        return .none
        
      case let .showRulings(.presented(action)):
        switch action {
        case .dismissTapped:
          state.showRulings = nil
          
        default:
          break
        }
        return .none
        
      case .showRulings:
        return .none
      }
    }
    .ifLet(\.$showRulings, action: \.showRulings) {
      RulingFeature(client: client)
    }
  }
}

extension CardDetailFeature {
  @ObservableState struct State: Equatable, Identifiable {
    @Presents var showRulings: RulingFeature<Client>.State?
    let id: UUID
    var content: Content<Client.MagicCardModel>
    let start: Action
    
    init(
      card: Client.MagicCardModel,
      entryPoint: EntryPoint<Client>
    ) {
      id = UUID()
      
      switch entryPoint {
      case .query:
        content = Content(card: card, setIconURL: nil)
        
      case let .set(value):
        content = Content(card: card, setIconURL: value.iconURL)
      }
      
      start = .fetchAdditionalInformation(card: card)
    }
  }
  
  @CasePathable indirect enum Action: Equatable {
    case dismissRulingsTapped
    case fetchAdditionalInformation(card: Client.MagicCardModel)
    case descriptionCallToActionTapped
    case updateSetIconURL(_ setIconURL: Result<URL?, FeatureError>)
    case updateVariants(_ variants: Result<[Client.MagicCardModel], FeatureError>)
    case viewAppeared(initialAction: Action)
    case viewRulingsTapped
    case showRulings(PresentationAction<RulingFeature<Client>.Action>)
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
