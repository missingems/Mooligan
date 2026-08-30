import ComposableArchitecture
import Combine
import Foundation
import ScryfallKit
import SwiftUI
import Networking

@Reducer
public struct QueryFeature: Sendable {
  @Dependency(\.cardQueryRequestClient) var client
  
  @ObservableState
  public struct State: Sendable {
    public enum Mode: Equatable, Sendable {
      case placeholder
      case data
      case loading
      case error(placeholder: Card?, isRetrying: Bool = false, isInitial: Bool = false)
      
      var isPlaceholder: Bool {
        if case .placeholder = self { return true }
        return false
      }
      
      var shouldHideTopBar: Bool {
        switch self {
        case .placeholder: return true
        case let .error(_, _, isInitial): return isInitial
        default: return false
        }
      }
      
      var isInitialError: Bool {
        if case let .error(_, _, isInitial) = self { return isInitial }
        return false
      }
      
      var isScrollable: Bool {
        switch self {
        case .placeholder: return false
        case .data: return true
        case .loading: return false
        case .error: return false
        }
      }
      
      var isLoading: Bool {
        switch self {
        case .placeholder: return true
        case .data: return false
        case .loading: return true
        case let .error(_, isRetrying, _): return isRetrying
        }
      }
      
      var hasError: Bool {
        switch self {
        case .loading, .data, .placeholder:
          return false
        case .error:
          return true
        }
      }
    }
    
    var mode: Mode
    let queryType: QueryType
    let title: String
    var isShowingInfo: Bool
    public internal(set) var dataSource: CardDataSource
    let availableColorTypeOptions: [Card.Color]
    let availableCardType: [SearchQuery.CardType]
    let availableSortModes: [SortMode]
    let availableSortOrders: [SortDirection]
    var query: SearchQuery
    var scrollPosition: ScrollPosition
    var numberOfColumns: Double = 2
    let searchPrompt: String
    public let id: UUID
    var isSearchExpanded: Bool
    
    public init(
      mode: Mode,
      queryType: QueryType
    ) {
      self.mode = mode
      self.queryType = queryType
      
      switch queryType {
      case let .querySet(set, request):
        title = set.name
        query = request
        id = set.id
        searchPrompt = String(localized: "Search \(set.cardCount) cards…")
        
      case let .search(request):
        title = String(localized: "Search")
        query = request
        id = UUID()
        searchPrompt = String(localized: "Search cards…")
      }
      
      dataSource = CardDataSource(cards: [], hasNextPage: false, total: 0)
      availableCardType = SearchQuery.CardType.allCases
      availableSortModes = [.name, .usd, .cmc, .color, .rarity, .released]
      availableSortOrders = [.asc, .desc]
      isShowingInfo = false
      scrollPosition = ScrollPosition(edge: .top)
      availableColorTypeOptions = Card.Color.allCases
      isSearchExpanded = false
    }
    
    func shouldLoadMore(at index: Int) -> Bool {
      (index == (dataSource.cardDetails.count) - 1) && dataSource.hasNextPage == true
    }
  }
  
  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case didSelectCard(Card, QueryType)
    case didSelectShowInfo
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards(CardDataSource?, SearchQuery, State.Mode)
    case scrollToTop
    case viewAppeared
    case cardFaceToggled(id: UUID)
    case performSearch
    case queryFailed(isInitial: Bool)
    case updatePlaceholderCard(Card?, isInitial: Bool)
    case retry
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
      .onChange(of: \.query) { oldValue, newValue in
        return .send(.performSearch)
      }
    
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
        
      case .performSearch:
        return .concatenate(
          [
            .run { [state] send in
              await send(
                .updateCards(state.dataSource, state.query, .loading),
                animation: .default
              )
            },
            .run { [query = state.query] send in
              let result = try await client.queryCards(query)
              
              await send(
                .updateCards(
                  CardDataSource(
                    cards: result.data,
                    hasNextPage: result.hasMore ?? false,
                    total: result.totalCards ?? 0
                  ),
                  query,
                  .data
                ),
                animation: .smooth
              )
            } catch: { error, send in
              await send(.queryFailed(isInitial: false), animation: .default)
            },
            .run { send in
              await send(.scrollToTop, animation: .default)
            },
          ]
        )
        .cancellable(
          id: "query",
          cancelInFlight: true
        )
        
      case .didSelectCard:
        return .none
        
      case .didSelectShowInfo:
        state.isShowingInfo = true
        return .none
        
      case let .loadMoreCardsIfNeeded(displayingIndex):
        guard
          displayingIndex == state.dataSource.cardDetails.count - 1,
          state.dataSource.hasNextPage == true
            else {
          return .none
        }
        
        return .run { [client, dataSource = state.dataSource, query = state.query.next()] send in
          let result = try await client.queryCards(query)
          var dataSource = dataSource
          dataSource.append(cards: result.data)
          dataSource.hasNextPage = result.hasMore ?? false
          
          await send(.updateCards(dataSource, query, .data))
        } catch: { error, send in
          await send(.queryFailed(isInitial: false), animation: .default)
        }
          .cancellable(
            id: "loadMoreCardsIfNeeded: \(displayingIndex), for query: \(state.queryType)",
            cancelInFlight: true
          )
        
      case let .updateCards(value, nextQuery, mode):
        if let value {
          state.dataSource = value
          state.query = nextQuery
          state.mode = mode
        }
        
        return .none
        
      case .scrollToTop:
        state.scrollPosition.scrollTo(edge: .top)
        return .none
        
      case .viewAppeared:
        return .concatenate(
          [
            .run { [state] send in
              if state.mode.isPlaceholder {
                let result = try await client.queryCards(state.query)
                
                await send(
                  .updateCards(
                    CardDataSource(
                      cards: result.data,
                      hasNextPage: result.hasMore ?? false,
                      total: result.totalCards ?? 0
                    ),
                    state.query,
                    .data
                  )
                )
              }
            } catch: { error, send in
              await send(.queryFailed(isInitial: true), animation: .default)
            }
          ]
        )
        
      case let .cardFaceToggled(id):
        guard let index = state.dataSource.cardDetails.firstIndex(where: { $0.card.id == id }),
              let currentImage = state.dataSource.cardDetails[index].displayableCardImage else {
          return .none
        }
        
        state.dataSource.cardDetails[index].displayableCardImage = currentImage.toggled()
        return .none
        
      case let .queryFailed(isInitial):
        return .run { [client] send in
          if isInitial {
            let card = try await client.randomlyQueryErrorCard()
            await send(.updatePlaceholderCard(card, isInitial: true))
          } else {
            await send(.updatePlaceholderCard(nil, isInitial: false))
          }
        }
        
      case .retry:
        if case let .error(card, _, isInitial) = state.mode {
          state.mode = .error(placeholder: card, isRetrying: true, isInitial: isInitial)
          return .run { [query = state.query] send in
            let result = try await client.queryCards(query)
            await send(
              .updateCards(
                CardDataSource(
                  cards: result.data,
                  hasNextPage: result.hasMore ?? false,
                  total: result.totalCards ?? 0
                ),
                query,
                .data
              ),
              animation: .smooth
            )
          } catch: { error, send in
            await send(.queryFailed(isInitial: isInitial), animation: .default)
          }
            .cancellable(id: "query", cancelInFlight: true)
        } else {
          state.mode = .placeholder
          return .run { send in
            try await Task.sleep(nanoseconds: 100_000_000)
            await send(.viewAppeared)
          }
        }
        
      case let .updatePlaceholderCard(card, isInitial):
        state.mode = .error(placeholder: card, isRetrying: false, isInitial: isInitial)
        state.dataSource = CardDataSource(cards: [], hasNextPage: false, total: 0)
        return .none
      }
    }
  }
  
  public init() {}
}
