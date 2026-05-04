import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit

@Reducer public struct CardDetailFeature: Sendable {
  @Dependency(\.cardDetailRequestClient) private var client
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didSelectVariant:
        return .none
        
      case let .didShowVariant(index):
        guard
          state.content.variants.state.value?.hasNextPage == true,
          index == state.content.variants.state.value?.cardDetails.count ?? 0 - 1
        else {
          return .none
        }
        
        return .run { [card = state.content.card, page = state.content.variants.page] send in
          await send(.fetchVariants(card: card, page: page + 1))
        }
        
      case let .fetchVariants(card, page):
        return .run { [existingVariants = state.content.variants.state.value] send in
          let result = try await client.getVariants(of: card, page: page)
          var _existingVariants = existingVariants
          
          let existingIDs = Set(_existingVariants?.cardDetails.map(\.id) ?? [])
          
          let newCards = result.data.filter {
            $0.id != card.id && !existingIDs.contains($0.id)  // dedupe against existing
          }
          
          _existingVariants?.append(cards: newCards)
          _existingVariants?.hasNextPage = result.hasMore ?? false
          _existingVariants?.total = result.totalCards ?? 0
          
          await send(
            .updateVariants(
              _existingVariants ??
              CardDataSource(
                cards: newCards,
                hasNextPage: result.hasMore ?? false,
                total: result.totalCards ?? 0
              ),
              page: page
            )
          )
        }
        
      case let .fetchAdditionalInformation(card):
        var effects: [EffectOf<Self>] = []
        
        if state.content.setIconURL == nil {
          effects.append(
            .run { send in
              try await send(.updateSetIconURL(URL(string: client.getSet(of: card).iconSvgUri)))
            }.cancellable(id: "updateSetIconURL: \(card.id.uuidString)", cancelInFlight: true)
          )
        }
        
        effects.append(
          .run { send in
            await send(.fetchVariants(card: card, page: 1))
          }.cancellable(id: "fetchVariants: \(card.id.uuidString)", cancelInFlight: true)
        )
        
        effects.append(
          .run { send in
            await send(.fetchRelatedTokens(card: card))
          }.cancellable(id: "fetchRelatedTokens: \(card.id.uuidString)", cancelInFlight: true)
        )
        
        effects.append(
          .run { send in
            await send(.fetchRelatedComboPieces(card: card))
          }.cancellable(id: "fetchRelatedComboPieces: \(card.id.uuidString)", cancelInFlight: true)
        )
        
        effects.append(
          .run { send in
            await send(.fetchRelatedMeldPieces(card: card))
          }.cancellable(id: "fetchRelatedMeldPieces: \(card.id.uuidString)", cancelInFlight: true)
        )
        
        effects.append(
          .run { send in
            await send(.fetchRelatedMeldResult(card: card))
          }.cancellable(id: "fetchRelatedMeldResult: \(card.id.uuidString)", cancelInFlight: true)
        )
        
        return .concatenate(
          .merge(effects),
          .send(.additionalInfosLoaded)
        )
        
      case .additionalInfosLoaded:
        state.hasAppeared = true
        return .none
        
      case .descriptionCallToActionTapped:
        switch state.content.displayableCardImage {
        case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName, id):
          state.content.displayableCardImage = .transformable(
            direction: direction.toggled(),
            frontImageURL: frontImageURL,
            backImageURL: backImageURL,
            callToActionIconName: callToActionIconName,
            id: id
          )
          
        case let .flippable(direction, displayingImageURL, callToActionIconName, id):
          state.content.displayableCardImage = .flippable(
            direction: direction.toggled(),
            displayingImageURL: displayingImageURL,
            callToActionIconName: callToActionIconName,
            id: id
          )
          
        default:
          fatalError("descriptionCallToActionTapped isn't available to single face card.")
        }
        
        return .none
        
      case let .fetchRelatedTokens(card):
        return .run { send in
          let dataSource = try await client.getRelatedCardsIfNeeded(
            of: card,
            for: .token
          )
          
          if let dataSource {
            await send(.updateRelatedTokens(dataSource))
          }
        }
        
      case let .fetchRelatedComboPieces(card):
        return .run { send in
          let dataSource = try await client.getRelatedCardsIfNeeded(
            of: card,
            for: .comboPiece
          )
          
          if let dataSource {
            await send(.updateComboPieces(dataSource))
          }
        }
        
      case let .fetchRelatedMeldPieces(card):
        return .run { send in
          let dataSource = try await client.getRelatedCardsIfNeeded(
            of: card,
            for: .meldPart
          )
          
          if let dataSource {
            await send(.updateMeldPieces(dataSource))
          }
        }
        
      case let .fetchRelatedMeldResult(card):
        return .run { send in
          let dataSource = try await client.getRelatedCardsIfNeeded(
            of: card,
            for: .meldResult
          )
          
          if let dataSource {
            await send(.updateMeldResult(dataSource))
          }
        }
        
      case let .updateSetIconURL(value):
        state.content.setIconURL = value
        return .none
        
      case let .updateVariants(value, page):
        state.content.variants = state.content.variants.updating(page: page, state: .data(value))
        return .none
        
      case let .updateMeldPieces(value):
        state.content.relatedMeldPieces = state.content.relatedMeldPieces?.updating(
          page: 1,
          state: .data(value)
        )
        return .none
        
      case let .updateMeldResult(value):
        state.content.relatedMeldResult = state.content.relatedMeldResult?.updating(
          page: 1,
          state: .data(value)
        )
        return .none
        
      case let .viewAppeared(action):
        guard !state.hasAppeared else { return .none }
        
        return .run { send in
          await send(action)
        }
        
      case .viewRulingsTapped:
        return .none
        
      case let .updateRelatedTokens(value):
        state.content.relatedTokens = state.content.relatedTokens?.updating(
          page: 1,
          state: .data(value)
        )
        return .none
        
      case let .updateComboPieces(value):
        state.content.relatedComboPieces = state.content.relatedComboPieces?.updating(
          page: 1,
          state: .data(value)
        )
        return .none
      }
    }
  }
  
  public init() {}
}

public extension CardDetailFeature {
  @ObservableState struct State: Equatable, Identifiable {
    public let id: UUID
    var content: Content
    var hasAppeared: Bool = false
    
    public init(card: Card, queryType: QueryType) {
      self.id = card.id
      self.content = Content(card: card, queryType: queryType)
    }
  }
  
  @CasePathable indirect enum Action: Equatable, Sendable {
    case didSelectVariant(card: Card, queryType: QueryType)
    case fetchAdditionalInformation(card: Card)
    case descriptionCallToActionTapped
    case updateSetIconURL(URL?)
    case updateVariants(CardDataSource, page: Int)
    case updateMeldPieces(CardDataSource)
    case updateMeldResult(CardDataSource)
    case didShowVariant(index: Int)
    case fetchVariants(card: Card, page: Int)
    case fetchRelatedTokens(card: Card)
    case fetchRelatedComboPieces(card: Card)
    case fetchRelatedMeldPieces(card: Card)
    case fetchRelatedMeldResult(card: Card)
    case viewAppeared(initialAction: Action)
    case viewRulingsTapped
    case updateRelatedTokens(CardDataSource)
    case updateComboPieces(CardDataSource)
    case additionalInfosLoaded
  }
}
