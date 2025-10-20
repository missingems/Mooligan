import ComposableArchitecture
import Combine
import Foundation
import ScryfallKit
import SwiftUI
import Networking

@Reducer
public struct QueryFeature {
  @Dependency(\.cardQueryRequestClient) var client
  
  @ObservableState
  public struct State {
    public enum Mode: Equatable {
      case placeholder
      case data
      case loading
      
      var isPlaceholder: Bool {
        switch self {
        case .placeholder:
          return true
          
        case .data:
          return false
          
        case .loading:
          return false
        }
      }
      
      var isScrollable: Bool {
        switch self {
        case .placeholder:
          return false
          
        case .data:
          return true
          
        case .loading:
          return false
        }
      }
    }
    
    var mode: Mode
    let queryType: QueryType
    let title: String
    var isShowingInfo: Bool
    var dataSource: CardDataSource?
    let availableSortModes: [SortMode]
    let availableSortOrders: [SortDirection]
    var query: SearchQuery
    var scrollPosition: ScrollPosition
    var numberOfColumns: Double = 2
    let searchPrompt: String
    public let id: UUID
    
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
        
      default:
        fatalError()
      }
      
      availableSortModes = [.name, .usd, .cmc, .color, .rarity, .released]
      availableSortOrders = [.asc, .desc, .auto]
      isShowingInfo = false
      scrollPosition = ScrollPosition(edge: .top)
    }
    
    func shouldLoadMore(at index: Int) -> Bool {
      (index == (dataSource?.cardDetails.count ?? 1) - 1) && dataSource?.hasNextPage == true
    }
  }
  
  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case didSelectCard(Card, QueryType)
    case didSelectCardType(SearchQuery.CardType)
    case didSelectShowInfo
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards(CardDataSource?, SearchQuery, State.Mode)
    case scrollToTop
    case viewAppeared
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding(\.query):
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
        
      case .binding:
        return .none
        
      case .didSelectCard:
        return .none
        
      case let .didSelectCardType(cardType):
        state.query.cardType = cardType
        
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
        
      case .didSelectShowInfo:
        state.isShowingInfo = true
        return .none
        
      case let .loadMoreCardsIfNeeded(displayingIndex):
        guard
          displayingIndex == (state.dataSource?.cardDetails.count ?? 1) - 1,
          state.dataSource?.hasNextPage == true
        else {
          return .none
        }
        
        return .run { [client, dataSource = state.dataSource, query = state.query.next()] send in
          let result = try await client.queryCards(query)
          var dataSource = dataSource
          dataSource?.append(cards: result.data)
          dataSource?.hasNextPage = result.hasMore ?? false
          
          await send(.updateCards(dataSource, query, .data))
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
                switch state.queryType {
                case let .querySet(set, _):
                  await send(
                    .updateCards(
                      CardDataSource(
                        cards: MockCardDetailRequestClient.generateMockCards(
                          number: min(10, set.cardCount)
                        ),
                        hasNextPage: false,
                        total: set.cardCount,
                      ),
                      state.query,
                      .placeholder
                    )
                  )
                  
                case .search:
                  fatalError("Unimplemented")
                }
              }
            },
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
            }
          ]
        )
      }
    }
  }
  
  public init() {}
}

extension QueryType {
  enum Section: Identifiable {
    case titleDetail(title: String, detail: String?)
    case titleIcon(title: String, iconURL: URL?)
    case titleCode(title: String, code: String)
    
    var id: String {
      switch self {
      case .titleDetail(let title, let detail):
        return "titleDetail" + title + (detail ?? "")
        
      case .titleIcon(let title, let iconURL):
        return "titleIcon" + title + (iconURL?.absoluteString ?? "")
        
      case .titleCode(let title, let code):
        return "titleCode" + title + code
      }
    }
  }
  
  var sections: [Section] {
    switch self {
    case .search:
      return []
      
    case let .querySet(value, _):
      return [
        .titleIcon(title: String(localized: "Set Symbol"), iconURL: URL(string: value.iconSvgUri)),
        .titleCode(title: String(localized: "Set Code"), code: value.code),
        .titleDetail(title: String(localized: "Release Date"), detail: value.releasedAt),
        .titleDetail(title: String(localized: "Number of Cards"), detail: "\(value.cardCount)"),
      ]
    }
  }
}
