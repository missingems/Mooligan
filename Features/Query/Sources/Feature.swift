import ComposableArchitecture
import Combine
import Foundation
import ScryfallKit
import SwiftUI
import Networking

@Reducer
public struct Feature {
  @Dependency(\.cardQueryRequestClient) var client
  
  @ObservableState
  public struct State {
    public enum Mode: Equatable {
      case placeholder
      case data
      
      var isPlaceholder: Bool {
        switch self {
        case .placeholder:
          return true
          
        case .data:
          return false
        }
      }
    }
    
    var mode: Mode
    var queryType: QueryType
    let title: String
    let searchPlaceholder: String
    let setReleasedDate: String?
    var isShowingInfo: Bool
    var isShowingSortOptions: Bool
    var isShowingSortFilters: Bool
    var dataSource: QueryDataSource?
    let availableSortModes: [SortMode]
    let availableSortOrders: [SortDirection]
    var query: Query
    var scrollPosition: ScrollPosition
    var viewWidth: CGFloat?
    var itemWidth: CGFloat?
    var numberOfColumns: Double = 2
    
    public init(
      mode: Mode,
      queryType: QueryType
    ) {
      self.mode = mode
      self.queryType = queryType
      
      switch queryType {
      case let .querySet(set, request):
        title = set.name
        searchPlaceholder = "Search \(set.cardCount) cards"
        
        if let dateString = set.releasedAt {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd"
          
          setReleasedDate = dateFormatter
            .date(from: dateString)?
            .formatted(date: .numeric, time: .omitted)
        } else {
          setReleasedDate = nil
        }
        
        self.query = request
        
      default:
        fatalError()
      }
      
      availableSortModes = [.usd, .name, .cmc, .color, .rarity, .released]
      availableSortOrders = [.asc, .desc, .auto]
      isShowingInfo = false
      isShowingSortOptions = false
      isShowingSortFilters = false
      scrollPosition = ScrollPosition(edge: .top)
    }
    
    func shouldLoadMore(at index: Int) -> Bool {
      (index == (dataSource?.cardDetails.count ?? 1) - 1) && dataSource?.hasNextPage == true
    }
  }
  
  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case didSelectCard(Card, QueryType)
    case didSelectShowInfo
    case didSelectShowSortOptions
    case didSelectShowFilters
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards(QueryDataSource?, Query, State.Mode)
    case viewAppeared
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding(\.viewWidth):
        if let viewWidth = state.viewWidth {
          state.itemWidth = (viewWidth - ((state.numberOfColumns - 1) * 8.0)) / state.numberOfColumns
        }
        
        return .none
        
      case .binding(\.query):
        state.isShowingSortOptions = false
        
        return .run { [query = state.query] send in
          let result = try await client.queryCards(query)
          
          await send(
            .updateCards(
              QueryDataSource(
                cards: result.data,
                focusedCard: nil,
                hasNextPage: result.hasMore ?? false
              ),
              query,
              .data
            ),
            animation: .default
          )
        }
        .cancellable(
          id: "query",
          cancelInFlight: true
        )
        
      case .binding:
        return .none
        
      case .didSelectCard:
        return .none
        
      case .didSelectShowInfo:
        state.isShowingInfo = true
        return .none
        
      case .didSelectShowFilters:
        state.isShowingSortFilters = true
        return .none
        
      case .didSelectShowSortOptions:
        state.isShowingSortOptions = true
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
          state.scrollPosition.scrollTo(edge: .top)
        }
        
        return .none
        
      case .viewAppeared:
        return .concatenate([
          .run(operation: { [state] send in
            if state.mode.isPlaceholder {
              switch state.queryType {
              case let .querySet(set, _):
                let mocks = MockCardDetailRequestClient.generateMockCards(number: min(10, set.cardCount))
                let dataSource = QueryDataSource(cards: mocks, focusedCard: nil, hasNextPage: false)
                await send(
                  .updateCards(
                    dataSource,
                    state.query,
                    .placeholder
                  )
                )
                
              case .search:
                fatalError("Unimplemented")
              }
            }
          }),
          .run(operation: { [state] send in
            if state.mode.isPlaceholder {
              let result = try await client.queryCards(state.query)
              let dataSource = QueryDataSource(cards: result.data, focusedCard: nil, hasNextPage: result.hasMore ?? false)
              await send(.updateCards(dataSource, state.query, .data))
            }
          })
        ])
      }
    }
  }
  
  public init() {}
}
