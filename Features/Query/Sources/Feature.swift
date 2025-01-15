import ComposableArchitecture
import Foundation
import ScryfallKit
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
    let setReleasedDate: Date?
    var dataSource: QueryDataSource?
    var sortMode: SortMode
    var sortOrder: SortDirection
    let availableSortModes: [SortMode]
    let availableSortOrders: [SortDirection]
    
    public init(
      mode: Mode,
      queryType: QueryType
    ) {
      self.mode = mode
      self.queryType = queryType
      
      switch queryType {
      case let .query(set, _, sortMode, sortDirection, _):
        title = set.name
        searchPlaceholder = "Search \(set.cardCount) cards"
        self.sortMode = sortMode
        sortOrder = sortDirection
        
        if let dateString = set.releasedAt {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd"
          
          setReleasedDate = dateFormatter.date(from: dateString)
        } else {
          setReleasedDate = nil
        }
        
      case let .search(query, _):
        title = query
        searchPlaceholder = "Search"
        setReleasedDate = nil
        sortMode = .name
        sortOrder = .auto
      }
      
      availableSortModes = [.usd, .name, .cmc, .color, .rarity, .released]
      availableSortOrders = [.asc, .desc, .auto]
    }
    
    func shouldLoadMore(at index: Int) -> Bool {
      (index == (dataSource?.cardDetails.count ?? 1) - 1) && dataSource?.hasNextPage == true
    }
  }
  
  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case didSelectCard(Card, QueryType)
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards(QueryDataSource?, QueryType, State.Mode)
    case viewAppeared
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.sortMode):
        if case let .query(set, filters, _, _, _) = state.queryType {
          state.sortOrder = .auto
          
          return .run { [state] send in
            let newQuery = QueryType.query(set, filters, state.sortMode, .auto, page: 1)
            let result = try await client.queryCards(newQuery)
            let dataSource = QueryDataSource(cards: result.data, focusedCard: nil, hasNextPage: result.hasMore ?? false)
            await send(.updateCards(dataSource, newQuery, .data))
          }
        } else {
          return .none
        }
        
      case .binding(\.sortOrder):
        if case let .query(set, filters, sortMode, _, _) = state.queryType {
          return .run { [state] send in
            let newQuery = QueryType.query(set, filters, sortMode, state.sortOrder, page: 1)
            let result = try await client.queryCards(newQuery)
            let dataSource = QueryDataSource(cards: result.data, focusedCard: nil, hasNextPage: result.hasMore ?? false)
            await send(.updateCards(dataSource, newQuery, .data))
          }
        } else {
          return .none
        }
        
      case .binding:
        return .none
        
      case .didSelectCard:
        return .none
        
      case let .loadMoreCardsIfNeeded(displayingIndex):
        guard
          displayingIndex == (state.dataSource?.cardDetails.count ?? 1) - 1,
          state.dataSource?.hasNextPage == true
        else {
          return .none
        }
        
        let nextQuery = state.queryType.next()
        
        return .run { [client, dataSource = state.dataSource] send in
          let result = try await client.queryCards(nextQuery)
          var dataSource = dataSource
          dataSource?.append(cards: result.data)
          dataSource?.hasNextPage = result.hasMore ?? false
          
          await send(.updateCards(dataSource, nextQuery, .data))
        }
        .cancellable(
          id: "loadMoreCardsIfNeeded: \(displayingIndex), for query: \(state.queryType)",
          cancelInFlight: true
        )
        
      case let .updateCards(value, nextQuery, mode):
        if let value {
          state.dataSource = value
          state.queryType = nextQuery
          state.mode = mode
        }
        
        return .none
        
      case .viewAppeared:
        return .concatenate([
          .run(operation: { [state] send in
            if state.mode.isPlaceholder {
              switch state.queryType {
              case let .query(set, filters, sourtMode, sortDirection, page):
                let mocks = MockCardDetailRequestClient.generateMockCards(number: min(10, set.cardCount))
                let dataSource = QueryDataSource(cards: mocks, focusedCard: nil, hasNextPage: false)
                await send(
                  .updateCards(
                    dataSource,
                    state.queryType,
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
              let result = try await client.queryCards(state.queryType)
              let dataSource = QueryDataSource(cards: result.data, focusedCard: nil, hasNextPage: result.hasMore ?? false)
              await send(.updateCards(dataSource, state.queryType, .data))
            }
          })
        ])
      }
    }
  }
  
  public init() {}
}
