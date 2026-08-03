import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit

@Reducer public struct CardDetailFeature: Sendable {
  @Dependency(\.cardDetailRequestClient) private var client
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      coreReduce(into: &state, action: action)
    }
    ._printChanges(.actionLabels)
  }
  
  private func coreReduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .didSelectVariant:
      return .none
      
    case let .didShowVariant(index):
      guard
        state.content.variants.state.value?.hasNextPage == true,
        // FIX: Added parentheses to ensure correct operator precedence
        index == (state.content.variants.state.value?.cardDetails.count ?? 0) - 1
          else { return .none }
      
      return .run { [card = state.content.card, page = state.content.variants.page] send in
        await send(.fetchVariants(card: card, page: page + 1))
      }
      
    case let .fetchAdditionalInformation(card):
      state.markAsAppeared()
      let needsSetIcon = state.content.setIconURL == nil
      
      // Split side effects into decoupled, concurrent requests
      return .merge(
        needsSetIcon ? .send(.fetchSetIcon(card: card)) : .none,
        .send(.fetchVariants(card: card, page: 1)),
        .send(.fetchRelatedTokens(card: card)),
        .send(.fetchRelatedComboPieces(card: card)),
        .send(.fetchRelatedMeldPieces(card: card)),
        .send(.fetchRelatedMeldResult(card: card))
      )
      .cancellable(id: "fetchAdditional: \(card.id.uuidString)", cancelInFlight: true)
      
    case let .fetchSetIcon(card):
      return .run { send in
        let setInfo = try await client.getSet(of: card)
        await send(.updateSetIconURL(URL(string: setInfo.iconSvgUri)))
      }
      
    case let .fetchVariants(card, page):
      return .run { [existingVariants = state.content.variants.state.value] send in
        do {
          let result = try await client.getVariants(of: card, page: page)
          var _existingVariants = existingVariants
          
          let existingIDs = Set(_existingVariants?.cardDetails.map(\.id) ?? [])
          let newCards = result.data.filter {
            $0.id != card.id && !existingIDs.contains($0.id)
          }
          
          _existingVariants?.append(cards: newCards)
          _existingVariants?.hasNextPage = result.hasMore ?? false
          _existingVariants?.total = result.totalCards ?? 0
          
          let newDataSource = _existingVariants ?? CardDataSource(
            cards: newCards,
            hasNextPage: result.hasMore ?? false,
            total: result.totalCards ?? 0
          )
          
          await send(.updateVariants(newDataSource, page: page))
        } catch {
          let fallback = existingVariants ?? CardDataSource(cards: [], hasNextPage: false, total: 0)
          await send(.updateVariants(fallback, page: page))
        }
      }
      
    case let .fetchRelatedTokens(card):
      return .run { send in
        do {
          if let dataSource = try await client.getRelatedCardsIfNeeded(of: card, for: .token) {
            await send(.updateRelatedTokens(dataSource))
          } else {
            await send(.updateRelatedTokens(CardDataSource(cards: [], hasNextPage: false, total: 0)))
          }
        } catch {
          await send(.updateRelatedTokens(CardDataSource(cards: [], hasNextPage: false, total: 0)))
        }
      }
      
    case let .fetchRelatedComboPieces(card):
      return .run { send in
        do {
          if let dataSource = try await client.getRelatedCardsIfNeeded(of: card, for: .comboPiece) {
            await send(.updateComboPieces(dataSource))
          } else {
            await send(.updateComboPieces(CardDataSource(cards: [], hasNextPage: false, total: 0)))
          }
        } catch {
          await send(.updateComboPieces(CardDataSource(cards: [], hasNextPage: false, total: 0)))
        }
      }
      
    case let .fetchRelatedMeldPieces(card):
      return .run { send in
        do {
          if let dataSource = try await client.getRelatedCardsIfNeeded(of: card, for: .meldPart) {
            await send(.updateMeldPieces(dataSource))
          } else {
            await send(.updateMeldPieces(CardDataSource(cards: [], hasNextPage: false, total: 0)))
          }
        } catch {
          await send(.updateMeldPieces(CardDataSource(cards: [], hasNextPage: false, total: 0)))
        }
      }
      
    case let .fetchRelatedMeldResult(card):
      return .run { send in
        do {
          if let dataSource = try await client.getRelatedCardsIfNeeded(of: card, for: .meldResult) {
            await send(.updateMeldResult(dataSource))
          } else {
            await send(.updateMeldResult(CardDataSource(cards: [], hasNextPage: false, total: 0)))
          }
        } catch {
          await send(.updateMeldResult(CardDataSource(cards: [], hasNextPage: false, total: 0)))
        }
      }
      
    case .descriptionCallToActionTapped:
      state.toggleCardImageDescription()
      return .none
      
    case let .updateSetIconURL(value):
      state.updateSetIconURL(value)
      return .none
      
    case let .updateVariants(value, page):
      state.updateVariants(value, page: page)
      return .none
      
    case let .updateMeldPieces(value):
      state.updateMeldPieces(value)
      return .none
      
    case let .updateMeldResult(value):
      state.updateMeldResult(value)
      return .none
      
    case let .updateRelatedTokens(value):
      state.updateRelatedTokens(value)
      return .none
      
    case let .updateComboPieces(value):
      state.updateComboPieces(value)
      return .none
      
    case let .viewAppeared(action):
      guard !state.hasAppeared else { return .none }
      return .send(action)
      
    case .viewRulingsTapped:
      return .none
    }
  }
}

// MARK: - State & Action Definitions
public extension CardDetailFeature {
  @ObservableState struct State: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var content: Content
    public var hasAppeared: Bool = false
    
    public init(card: Card, displayableCardImage: DisplayableCardImage? = nil, queryType: QueryType) {
      self.id = card.id
      self.content = Content(card: card, queryType: queryType)
      
      if let displayableCardImage {
        self.content.displayableCardImage = displayableCardImage
      }
    }
  }
  
  @CasePathable indirect enum Action: Equatable, Sendable {
    // User Actions
    case descriptionCallToActionTapped
    case didSelectVariant(card: Card, queryType: QueryType)
    case didShowVariant(index: Int)
    case viewAppeared(initialAction: Action)
    case viewRulingsTapped
    
    // Fetch Actions
    case fetchAdditionalInformation(card: Card)
    case fetchSetIcon(card: Card)
    case fetchVariants(card: Card, page: Int)
    case fetchRelatedTokens(card: Card)
    case fetchRelatedComboPieces(card: Card)
    case fetchRelatedMeldPieces(card: Card)
    case fetchRelatedMeldResult(card: Card)
    
    // Update/Response Actions
    case updateSetIconURL(URL?)
    case updateVariants(CardDataSource, page: Int)
    case updateRelatedTokens(CardDataSource)
    case updateComboPieces(CardDataSource)
    case updateMeldPieces(CardDataSource)
    case updateMeldResult(CardDataSource)
  }
}

// MARK: - State Mutations
private extension CardDetailFeature.State {
  mutating func markAsAppeared() {
    hasAppeared = true
  }
  
  mutating func updateSetIconURL(_ url: URL?) {
    if let url { content.setIconURL = url }
  }
  
  mutating func updateVariants(_ dataSource: CardDataSource, page: Int) {
    content.variants = content.variants.updating(page: page, state: .data(dataSource))
  }
  
  mutating func updateRelatedTokens(_ dataSource: CardDataSource) {
    content.relatedTokens = content.relatedTokens?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func updateComboPieces(_ dataSource: CardDataSource) {
    content.relatedComboPieces = content.relatedComboPieces?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func updateMeldPieces(_ dataSource: CardDataSource) {
    content.relatedMeldPieces = content.relatedMeldPieces?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func updateMeldResult(_ dataSource: CardDataSource) {
    content.relatedMeldResult = content.relatedMeldResult?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func toggleCardImageDescription() {
    switch content.displayableCardImage {
    case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName, id):
      content.displayableCardImage = .transformable(
        direction: direction.toggled(), frontImageURL: frontImageURL,
        backImageURL: backImageURL, callToActionIconName: callToActionIconName, id: id
      )
      
    case let .flippable(direction, displayingImageURL, callToActionIconName, id):
      content.displayableCardImage = .flippable(
        direction: direction.toggled(), displayingImageURL: displayingImageURL,
        callToActionIconName: callToActionIconName, id: id
      )
      
    default:
      fatalError("descriptionCallToActionTapped isn't available to single face card.")
    }
  }
}
