import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit

@Reducer struct CardDetailFeature {
  @Dependency(\.cardDetailRequestClient) private var client
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .dismissRulingsTapped:
        state.showRulings = nil
        return .none
        
      case let .fetchAdditionalInformation(card):
        var effects: [EffectOf<Self>] = []
        
        if state.content.setIconURL == nil {
          effects.append(
            .run { send in
              try await send(.updateSetIconURL(URL(string: client.getSet(of: card).iconSvgUri)))
            }.cancellable(id: "getSet: \(card.id.uuidString)", cancelInFlight: true)
          )
        }
        
        if state.content.variants.isEmpty {
          effects.append(
            .run { send in
              try await send(.updateVariants(client.getVariants(of: card, page: 0)))
            }.cancellable(id: "getVariants: \(card.id.uuidString)", cancelInFlight: true)
          )
        }
        
        return .merge(effects)
        
      case .descriptionCallToActionTapped:
        switch state.content.selectedMode {
        case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName):
          state.content.selectedMode = .transformable(
            direction: direction.toggled(),
            frontImageURL: frontImageURL,
            backImageURL: backImageURL,
            callToActionIconName: callToActionIconName
          )
          
        case let .flippable(direction, displayingImageURL, callToActionIconName):
          state.content.selectedMode = .flippable(
            direction: direction.toggled(),
            displayingImageURL: displayingImageURL,
            callToActionIconName: callToActionIconName
          )
          
        case .single:
          fatalError("descriptionCallToActionTapped isn't available to single face card.")
        }

        return .none
        
      case let .updateSetIconURL(value):
        state.content.setIconURL = value
        return .none
        
      case let .updateVariants(value):
        state.content.variants = IdentifiedArray(uniqueElements: value)
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
      RulingFeature()
    }
  }
}

extension CardDetailFeature {
  @ObservableState struct State: Equatable, Identifiable {
    @Presents var showRulings: RulingFeature.State?
    let id: UUID
    var content: Content
    let start: Action
    
    init(
      card: Card,
      entryPoint: EntryPoint
    ) {
      id = UUID()
      
      switch entryPoint {
      case .query:
        content = Content(card: card, setIconURL: nil)
        
      case let .set(value):
        content = Content(card: card, setIconURL: URL(string: value.iconSvgUri))
      }
      
      start = .fetchAdditionalInformation(card: card)
    }
  }
  
  @CasePathable indirect enum Action: Equatable {
    case dismissRulingsTapped
    case fetchAdditionalInformation(card: Card)
    case descriptionCallToActionTapped
    case updateSetIconURL(URL?)
    case updateVariants([Card])
    case viewAppeared(initialAction: Action)
    case viewRulingsTapped
    case showRulings(PresentationAction<RulingFeature.Action>)
  }
}
