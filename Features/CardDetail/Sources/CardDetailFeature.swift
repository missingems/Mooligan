import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit

@Reducer public struct CardDetailFeature {
  @Dependency(\.cardDetailRequestClient) private var client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didShowVariant(index):
        return .none
        
      case .dismissRulingsTapped:
        state.showRulings = nil
        return .none
        
      case let .fetchAdditionalInformation(card):
        var effects: [EffectOf<Self>] = []
        
        if state.content?.setIconURL == nil {
          effects.append(
            .run { send in
              try await send(.updateSetIconURL(URL(string: client.getSet(of: card).iconSvgUri)))
            }.cancellable(id: "getSet: \(card.id.uuidString)", cancelInFlight: true)
          )
        }
        
        effects.append(
          .run { send in
//            try await send(
//              .updateVariants(
//                IdentifiedArray(uniqueElements: client.getVariants(of: card, page: 0).data)
//              )
//            )
          }.cancellable(id: "getVariants: \(card.id.uuidString)", cancelInFlight: true)
        )
        
        return .merge(effects)
        
      case .descriptionCallToActionTapped:
        switch state.content?.displayableCardImage {
        case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName, id):
          state.content?.displayableCardImage = .transformable(
            direction: direction.toggled(),
            frontImageURL: frontImageURL,
            backImageURL: backImageURL,
            callToActionIconName: callToActionIconName,
            id: id
          )
          
        case let .flippable(direction, displayingImageURL, callToActionIconName, id):
          state.content?.displayableCardImage = .flippable(
            direction: direction.toggled(),
            displayingImageURL: displayingImageURL,
            callToActionIconName: callToActionIconName,
            id: id
          )
          
        default:
          fatalError("descriptionCallToActionTapped isn't available to single face card.")
        }

        return .none
        
      case let .updateSetIconURL(value):
        state.content?.setIconURL = value
        return .none
        
      case let .updateVariants(value):
        state.content?.variants = value
        return .none
        
      case let .viewAppeared(action):
        return .run { send in
          await send(action)
        }
        
      case .viewRulingsTapped:
        if let card = state.content?.card {
          state.showRulings = RulingFeature.State(
            card: card,
            title: "Rulings"
          )
        }
        
        return .none
        
      case let .setupContentIfNeeded(card, queryType):
        guard state.content == nil else {
          return .none
        }
        
        return .run { send in
          let content: Content
          
          switch queryType {
          case .search:
            content = Content(card: card, setIconURL: nil)
            
          case let .querySet(value, _):
            content = Content(card: card, setIconURL: URL(string: value.iconSvgUri))
          }
          
          await send(.updateContent(content))
        }
        
      case let .updateContent(value):
        state.content = value
        
        return .run { send in
          await send(.fetchAdditionalInformation(card: value.card))
        }
        
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
      RulingFeature()
    }
  }
  
  public init() {}
}

public extension CardDetailFeature {
  @ObservableState struct State: Equatable {
    @Presents var showRulings: RulingFeature.State?
    public let id: UUID
    var content: Content?
    let start: Action
    
    public init(card: Card, queryType: QueryType) {
      self.id = card.id
      start = .setupContentIfNeeded(card: card, queryType: queryType)
    }
  }
  
  @CasePathable indirect enum Action: Equatable {
    case dismissRulingsTapped
    case fetchAdditionalInformation(card: Card)
    case descriptionCallToActionTapped
    case updateSetIconURL(URL?)
    case updateVariants(CardDataSource)
    case didShowVariant(index: Int)
    case viewAppeared(initialAction: Action)
    case viewRulingsTapped
    case setupContentIfNeeded(card: Card, queryType: QueryType)
    case updateContent(Content)
    case showRulings(PresentationAction<RulingFeature.Action>)
  }
}
