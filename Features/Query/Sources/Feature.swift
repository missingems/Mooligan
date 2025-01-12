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
    var dataSource: QueryDataSource?
    
    public init(
      mode: Mode,
      queryType: QueryType
    ) {
      self.mode = mode
      self.queryType = queryType
      
      switch queryType {
      case let .set(set, _):
        title = set.name
        searchPlaceholder = "Search \(set.cardCount) cards"
        
      case let .search(query, _):
        title = query
        searchPlaceholder = "Search"
      }
    }
    
    func shouldLoadMore(at index: Int) -> Bool {
      (index == (dataSource?.cardDetails.count ?? 1) - 1) && dataSource?.hasNextPage == true
    }
  }
  
  public enum Action: Equatable {
    case didSelectCard(Card, QueryType)
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards(QueryDataSource?, QueryType, State.Mode)
    case viewAppeared
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
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
              case let .set(value, _):
                let mocks = MockCardDetailRequestClient.generateMockCards(number: min(10, value.cardCount))
                let dataSource = QueryDataSource(cards: mocks, focusedCard: nil, hasNextPage: false)
                await send(.updateCards(dataSource, state.queryType, .placeholder))
                
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
