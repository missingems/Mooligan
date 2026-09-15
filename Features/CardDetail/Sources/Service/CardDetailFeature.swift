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
      
    case .viewAppeared:
      guard !state.hasAppeared else { return .none }
      state.hasAppeared = true
      let card = state.content.card

      // Every action is checked by each card's store in the pager, so the sections come back
      // together in one action and price history in another, instead of one action per fetch.
      return .merge(
        loadAdditionalInformation(
          card: card,
          needsSetIcon: state.setIconURL == nil,
          existingVariants: state.variants.state.value
        ),
        fetchPriceHistory(card: card, state: &state)
      )

    case let .fetchVariants(card, page):
      return .run { [existingVariants = state.variants.state.value] send in
        let dataSource = await variants(of: card, page: page, existing: existingVariants)
        await send(.updateVariants(dataSource, page: page))
      }
      
    case let .fetchPriceHistory(card):
      return fetchPriceHistory(card: card, state: &state)

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

    case let .updatePurchaseLinks(value):
      state.updatePurchaseLinks(value)
      return .none
      
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
    .cancellable(id: "fetchAdditional: \(card.id.uuidString)", cancelInFlight: true)
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

    return .run(priority: .background) { [setClient] send in
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
