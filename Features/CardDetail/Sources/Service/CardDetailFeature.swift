import ComposableArchitecture
import DesignComponents
import Foundation
import Networking
import ScryfallKit

@Reducer public struct CardDetailFeature: Sendable {
  @Dependency(\.cardDetailRequestClient) private var client
  @Dependency(\.priceHistoryClient) private var priceHistoryClient
  @Dependency(\.continuousClock) private var clock
  @Dependency(\.gameSetRequestClient) private var setClient
  @Dependency(\.cardPullOddsSource) private var pullOddsSource
  
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
        let variants = state.variants.state.value,
        variants.hasNextPage,
        index == variants.cardDetails.count - 1
      else { return .none }
      
      return .run { [card = state.content.card, page = state.variants.page] send in
        await send(.fetchVariants(card: card, page: page + 1))
      }
      
    case .viewAppeared:
      let card = state.content.card

      // Only what has not landed yet: a page that left while loading comes back here with its
      // in-flight loads cancelled, and reloads just those. Every action is checked by each card's
      // store in the pager, so the sections come back together in one action, and price history and
      // the pull odds in one each, instead of one action per fetch. The odds are not folded in with
      // the sections: the first card of a set waits on a set file of several megabytes for them,
      // and the prints and related cards should not wait with it.
      var effects: [Effect<Action>] = []
      if state.variants.state.isInitial {
        effects.append(loadAdditionalInformation(
          card: card,
          needsSetIcon: state.setIconURL == nil,
          existingVariants: state.variants.state.value
        ))
      }
      if state.priceHistory.status == .loading {
        effects.append(fetchPriceHistory(card: card, state: &state))
      }
      if state.pullOdds == .loading {
        effects.append(loadPullOdds(card: card, queryType: state.content.queryType))
      }
      return .merge(effects)

    case let .fetchVariants(card, page):
      return .run { [existingVariants = state.variants.state.value] send in
        let dataSource = await variants(of: card, page: page, existing: existingVariants)
        await send(.updateVariants(dataSource, page: page))
      }
      
    case let .fetchPriceHistory(card):
      return fetchPriceHistory(card: card, state: &state)

    case .retryPriceHistoryTapped:
      return .send(.fetchPriceHistory(card: state.content.card))

    case .descriptionCallToActionTapped:
      state.toggleCardImageDescription()
      return .none
      
    case let .updateAdditionalInformation(information):
      state.updateAdditionalInformation(information)
      return .none
      
    case let .updateVariants(value, page):
      state.updateVariants(value, page: page)
      return .none
      
    case let .updatePriceHistory(update):
      state.updatePriceHistory(update.display)
      return .none

    case let .updatePullOdds(odds):
      state.pullOdds = odds.map(PullOddsStatus.loaded) ?? .unavailable
      return .none
    case .viewRulingsTapped:
      return .none
    }
  }
}

extension CardDetailFeature {
  enum CancelID: Hashable, Sendable {
    case priceHistory(UUID)
    case additionalInformation(UUID)
    case pullOdds(UUID)
  }

  private func loadAdditionalInformation(
    card: Card,
    needsSetIcon: Bool,
    existingVariants: CardDataSource?
  ) -> Effect<Action> {
    .run { send in
      async let iconURL = needsSetIcon ? setIconURL(of: card) : nil
      async let firstPage = variants(of: card, page: 1, existing: existingVariants)
      async let tokens = relatedCards(of: card, for: .token)
      async let comboPieces = relatedCards(of: card, for: .comboPiece)
      async let meldPieces = relatedCards(of: card, for: .meldPart)
      async let meldResult = relatedCards(of: card, for: .meldResult)

      await send(.updateAdditionalInformation(AdditionalInformation(
        setIconURL: await iconURL,
        variants: await firstPage,
        relatedTokens: await tokens,
        relatedComboPieces: await comboPieces,
        relatedMeldPieces: await meldPieces,
        relatedMeldResult: await meldResult
      )))
    }
    .cancellable(id: CancelID.additionalInformation(card.id), cancelInFlight: true)
  }

  private func loadPullOdds(card: Card, queryType: QueryType) -> Effect<Action> {
    .run(priority: .utility) { send in
      // A commander deck's cards are opened in its parent set's Collector Booster, so the odds need
      // the parent. Browsing a set already has the set in hand; a search asks the set client, which
      // answers from the local database.
      var set: MTGSet?
      if case let .querySet(browsed, _) = queryType, browsed.code.lowercased() == card.set.lowercased() {
        set = browsed
      } else {
        set = try? await client.getSet(of: card)
      }

      let odds = await pullOddsSource.odds(for: card, parentSetCode: set?.parentSetCode)
      // Left in the loading state when the page has gone, so it loads again when it comes back.
      guard Task.isCancelled == false else { return }
      await send(.updatePullOdds(odds))
    }
    .cancellable(id: CancelID.pullOdds(card.id), cancelInFlight: true)
  }

  private func setIconURL(of card: Card) async -> URL? {
    guard let set = try? await client.getSet(of: card) else { return nil }
    return URL(string: set.iconSvgUri)
  }

  private func variants(of card: Card, page: Int, existing: CardDataSource?) async -> CardDataSource {
    do {
      let result = try await client.getVariants(of: card, page: page)
      let existingIDs = Set(existing?.cardDetails.map(\.id) ?? [])
      let newCards = result.data.filter {
        $0.id != card.id && !existingIDs.contains($0.id)
      }

      guard var existing else {
        return CardDataSource(cards: newCards, hasNextPage: result.hasMore ?? false, total: result.totalCards ?? 0)
      }
      existing.append(cards: newCards)
      existing.hasNextPage = result.hasMore ?? false
      existing.total = result.totalCards ?? 0
      return existing
    } catch {
      return existing ?? .empty
    }
  }

  private func relatedCards(of card: Card, for component: Card.RelatedCard.Component) async -> CardDataSource {
    (try? await client.getRelatedCardsIfNeeded(of: card, for: component)) ?? .empty
  }

  private func fetchPriceHistory(card: Card, state: inout State) -> Effect<Action> {
    let labels = state.content.priceHistoryLabels
    if state.priceHistory.status != .loading {
      state.updatePriceHistory(.loading(card: card, labels: labels))
    }
    return loadPriceHistory(card: card, labels: labels)
  }

  private func loadPriceHistory(card: Card, labels: PriceHistoryLabels) -> Effect<Action> {
    let loader = PriceHistoryLoader(client: priceHistoryClient, clock: clock)

    // Utility, not background: the reader is looking at the placeholder this fills, and the
    // system schedules background work last when the main thread is busy drawing a swipe.
    return .run(priority: .utility) { [setClient] send in
      async let outcome = loader.load(card: card, requests: PriceHistorySection.priceRequests)
      async let releases = SetReleaseMarkerStore.shared.markers(in: .allPriceHistory) {
        (try? await setClient.getSets(queryType: .all).1) ?? []
      }

      let loaded = await outcome
      // The page may have left while the feed answered. Cancelled, the effect stops here: the
      // series, plot points, axis and every formatted price below are only made for a page that
      // is still on screen to show them.
      guard Task.isCancelled == false else { return }
      let result: PriceHistoryState = switch loaded {
      case let .loaded(histories):
        PriceHistorySection.makeState(
          card: card,
          history: histories[PriceHistorySection.chartRequest],
          buylistQuote: PriceHistorySection.buylistQuote(from: histories),
          releases: await releases
        )
      case .noData:
        // The feed has nothing for this card; a Scryfall quote alone still draws a flat week.
        PriceHistorySection.makeState(card: card, history: nil, releases: await releases)
      case .failed:
        .failed
      }

      let display = PriceHistoryDisplay.make(card: card, state: result, labels: labels)
      guard Task.isCancelled == false else { return }
      await send(.updatePriceHistory(PriceHistoryUpdate(display: display)))
    }
    .cancellable(id: CancelID.priceHistory(card.id), cancelInFlight: true)
  }
}
