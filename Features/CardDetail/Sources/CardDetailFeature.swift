import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit

@Reducer public struct CardDetailFeature: Sendable {
  @Dependency(\.cardDetailRequestClient) private var client
  @Dependency(\.priceHistoryClient) private var priceHistoryClient
  @Dependency(\.purchaseLinksClient) private var purchaseLinksClient
  @Dependency(\.continuousClock) private var clock
  @Dependency(\.gameSetRequestClient) private var setClient
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      coreReduce(into: &state, action: action)
    }
  }
  
  private func coreReduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .didSelectVariant:
      return .none
      
    case let .didShowVariant(index):
      guard
        state.variants.state.value?.hasNextPage == true,
        index == (state.variants.state.value?.cardDetails.count ?? 0) - 1
          else { return .none }
      
      return .run { [card = state.content.card, page = state.variants.page] send in
        await send(.fetchVariants(card: card, page: page + 1))
      }
      
    case let .fetchAdditionalInformation(card):
      state.markAsAppeared()
      let needsSetIcon = state.setIconURL == nil
      
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
      return .run { [existingVariants = state.variants.state.value] send in
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
      
    case .priceHistoryAppeared:
      guard state.priceHistory.status == .loading else { return .none }
      return loadPriceHistory(
        card: state.content.card,
        labels: state.content.priceHistoryLabels,
        after: Self.priceHistoryDebounce
      )

    case .priceHistoryDisappeared:
      return .cancel(id: CancelID.priceHistory(state.id))

    case let .fetchPriceHistory(card):
      let labels = state.content.priceHistoryLabels
      if state.priceHistory.status != .loading {
        state.updatePriceHistory(.loading(card: card, labels: labels))
      }
      return loadPriceHistory(card: card, labels: labels, after: .zero)

    case .retryPriceHistoryTapped:
      return .send(.fetchPriceHistory(card: state.content.card))

    case .purchaseLinksRequested:
      switch state.purchaseLinks {
      case .loading, .loaded:
        return .none
      case .idle, .failed:
        break
      }
      state.updatePurchaseLinks(.loading)

      return .run { [card = state.content.card] send in
        do {
          await send(.updatePurchaseLinks(.loaded(try await purchaseLinksClient.purchaseLinks(for: card))))
        } catch let error as PriceHistoryClientError where error == .emptyResponse {
          await send(.updatePurchaseLinks(.loaded([])))
        } catch {
          await send(.updatePurchaseLinks(.failed))
        }
      }
      .cancellable(id: CancelID.purchaseLinks(state.content.card.id), cancelInFlight: true)

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
      
    case let .updatePriceHistory(update):
      state.updatePriceHistory(update.display)
      return .none

    case let .updatePurchaseLinks(value):
      state.updatePurchaseLinks(value)
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

extension CardDetailFeature {
  enum CancelID: Hashable, Sendable {
    case priceHistory(UUID)
    case purchaseLinks(UUID)
  }

  /// How long the pager has to rest on a card before its prices are requested. Swiping on to
  /// another card within this cancels the load before any request is made.
  static let priceHistoryDebounce: Duration = .milliseconds(400)

  private func loadPriceHistory(card: Card, labels: PriceHistoryLabels, after delay: Duration) -> Effect<Action> {
    let loader = PriceHistoryLoader(client: priceHistoryClient, clock: clock)

    return .run(priority: .background) { [clock, setClient] send in
      if delay > .zero {
        try await clock.sleep(for: delay)
      }

      async let outcome = loader.load(card: card, requests: PriceHistorySection.priceRequests)
      async let releases = SetReleaseMarkerStore.shared.markers(in: .allPriceHistory) {
        (try? await setClient.getSets(queryType: .all).1) ?? []
      }

      let result: PriceHistoryState = switch await outcome {
      case let .loaded(histories):
        PriceHistorySection.makeState(
          card: card,
          history: histories[PriceHistorySection.chartRequest],
          buylistQuote: PriceHistorySection.buylistQuote(from: histories),
          retailQuotes: PriceHistorySection.retailQuotes(from: histories),
          releases: await releases
        )
      case .noData:
        .unavailable
      case .failed:
        .failed
      }

      let display = PriceHistoryDisplay.make(card: card, state: result, labels: labels)
      await send(.updatePriceHistory(PriceHistoryUpdate(display: display)))
    }
    .cancellable(id: CancelID.priceHistory(card.id), cancelInFlight: true)
  }
}

// MARK: - State & Action Definitions
public extension CardDetailFeature {
  @ObservableState struct State: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var content: Content
    var priceHistory: PriceHistoryDisplay
    public var purchaseLinks: PurchaseLinksState = .idle
    var purchaseDropdown: PurchaseDropdownState = .loading
    public var setIconURL: URL?
    var variants: Content.SubContent
    var relatedTokens: Content.SubContent?
    var relatedComboPieces: Content.SubContent?
    var relatedMeldPieces: Content.SubContent?
    var relatedMeldResult: Content.SubContent?
    public var displayableCardImage: DisplayableCardImage?
    public var hasAppeared: Bool = false
    
    public init(card: Card, displayableCardImage: DisplayableCardImage? = nil, queryType: QueryType) {
      self.id = card.id
      let content = Content(card: card, queryType: queryType)
      self.content = content
      self.priceHistory = .loading(card: card, labels: content.priceHistoryLabels)
      
      setIconURL = Content.initialSetIconURL(queryType: queryType)
      variants = Content.initialVariants(card: card)
      relatedTokens = Content.initialRelatedTokens
      relatedComboPieces = Content.initialRelatedComboPieces
      relatedMeldPieces = Content.initialRelatedMeldPieces
      relatedMeldResult = Content.initialRelatedMeldResult
      self.displayableCardImage = displayableCardImage ?? DisplayableCardImage(card)
    }
  }
  
  @CasePathable indirect enum Action: Equatable, Sendable {
    // User Actions
    case descriptionCallToActionTapped
    case didSelectVariant(card: Card, queryType: QueryType)
    case didShowVariant(index: Int)
    case viewAppeared(initialAction: Action)
    case viewRulingsTapped
    case retryPriceHistoryTapped
    case purchaseLinksRequested
    /// The pager settled on this card: load its price history after a short debounce.
    case priceHistoryAppeared
    /// The pager settled on another card: cancel a price history load that has not landed yet.
    case priceHistoryDisappeared
    
    // Fetch Actions
    case fetchAdditionalInformation(card: Card)
    case fetchSetIcon(card: Card)
    case fetchVariants(card: Card, page: Int)
    case fetchPriceHistory(card: Card)
    case fetchRelatedTokens(card: Card)
    case fetchRelatedComboPieces(card: Card)
    case fetchRelatedMeldPieces(card: Card)
    case fetchRelatedMeldResult(card: Card)
    
    // Update/Response Actions
    case updateSetIconURL(URL?)
    case updateVariants(CardDataSource, page: Int)
    case updatePriceHistory(PriceHistoryUpdate)
    case updatePurchaseLinks(PurchaseLinksState)
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
    if let url { setIconURL = url }
  }
  
  mutating func updateVariants(_ dataSource: CardDataSource, page: Int) {
    variants = variants.updating(page: page, state: .data(dataSource))
  }

  mutating func updatePriceHistory(_ display: PriceHistoryDisplay) {
    priceHistory = display
    refreshPurchaseDropdown()
  }

  mutating func updatePurchaseLinks(_ links: PurchaseLinksState) {
    purchaseLinks = links
    refreshPurchaseDropdown()
  }

  mutating func refreshPurchaseDropdown() {
    purchaseDropdown = .make(
      links: purchaseLinks,
      quotes: priceHistory.retailQuotes,
      scryfallPrices: content.card.prices
    )
  }
  
  mutating func updateRelatedTokens(_ dataSource: CardDataSource) {
    relatedTokens = relatedTokens?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func updateComboPieces(_ dataSource: CardDataSource) {
    relatedComboPieces = relatedComboPieces?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func updateMeldPieces(_ dataSource: CardDataSource) {
    relatedMeldPieces = relatedMeldPieces?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func updateMeldResult(_ dataSource: CardDataSource) {
    relatedMeldResult = relatedMeldResult?.updating(page: 1, state: .data(dataSource))
  }
  
  mutating func toggleCardImageDescription() {
    switch displayableCardImage {
    case let .transformable(direction, frontImageURL, backImageURL, callToActionIconName, id):
      displayableCardImage = .transformable(
        direction: direction.toggled(), frontImageURL: frontImageURL,
        backImageURL: backImageURL, callToActionIconName: callToActionIconName, id: id
      )
      
    case let .flippable(direction, displayingImageURL, callToActionIconName, id):
      displayableCardImage = .flippable(
        direction: direction.toggled(), displayingImageURL: displayingImageURL,
        callToActionIconName: callToActionIconName, id: id
      )
      
    default:
      fatalError("descriptionCallToActionTapped isn't available to single face card.")
    }
  }
}
