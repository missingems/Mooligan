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
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
        
      case .dismissRulingsTapped:
        state.showRulings = nil
        return .none
        
      case let .fetchAdditionalInformation(card):
        if state.content.variants.isEmpty, (try? state.content.setIconURL.get()) == nil {
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
        } else {
          return .none
        }
        
      case .descriptionCallToActionTapped:
        if state.content.card.isFlippable {
          state.isFlipped?.toggle()
        } else if state.content.card.isTransformable {
          state.isTransformed?.toggle()
        }
        
        return .none
        
      case let .updateSetIconURL(value):
        state.content.setIconURL = value
        return .none
        
      case let .updateVariants(value):
        if let cards = try? value.get() {
          state.content.variants = IdentifiedArray(uniqueElements: cards.compactMap(CardView.Model.init))
        }
        
        return .none
        
      case let .variantFaceDirectionToggled(model):
//        state.content.variants = state.content.variants.elements
        if let index = state.content.variants.firstIndex(where: { element in
          return element == model
        }) {
          switch model {
          case let .transformable(direction: direction, frontImageURL, backImageURL):
            let newModel = CardView<Client.MagicCardModel>.Model.transformable(direction: direction == .back ? .front : .back, frontImageURL: frontImageURL, backImageURL: backImageURL)
            state.content.variants[index] = newModel
          default:
            break
          }
        }
        
//        if let existingModel = copy.first { $0.}
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
    
    var isTransformed: Bool? = false {
      didSet {
        content.faceDirection = content.faceDirection.toggled()
      }
    }
    
    var isFlipped: Bool? = false {
      didSet {
        content.faceDirection = content.faceDirection.toggled()
      }
    }
    
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
  
  @CasePathable indirect enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case dismissRulingsTapped
    case fetchAdditionalInformation(card: Client.MagicCardModel)
    case descriptionCallToActionTapped
    case updateSetIconURL(_ setIconURL: Result<URL?, FeatureError>)
    case updateVariants(_ variants: Result<[Client.MagicCardModel], FeatureError>)
    case variantFaceDirectionToggled(CardView<Client.MagicCardModel>.Model)
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
