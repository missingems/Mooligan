import ComposableArchitecture
import Foundation
import ScryfallKit
import Networking

@Reducer
public struct Feature {
  @Dependency(\.cardQueryRequestClient) var client
  
  @ObservableState
  public struct State: Equatable {
    public enum Mode: Equatable {
      case placeholder(numberOfDataSource: Int)
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
    var dataSource: QueryDataSource
    
    public init(
      mode: Mode,
      queryType: QueryType
    ) {
      self.mode = mode
      self.queryType = queryType
      
      self.dataSource = QueryDataSource(queryType: queryType, cards: IdentifiedArray(
        uniqueElements: MockCardDetailRequestClient.generateMockCards(
          number: 10
        )
      ), focusedCard: nil, hasNextPage: false)
    }
  }
  
  public enum Action: Equatable {
    case didSelectCard(Card)
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards([Card], hasNextPage: Bool, queryType: QueryType)
    case routeToCardDetail(QueryDataSource)
    case viewAppeared
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .routeToCardDetail:
        return .none
        
      case let .didSelectCard(card):
        state.dataSource.focusedCard = card
        
        return .run { [state] send in
          await send(.routeToCardDetail(state.dataSource))
        }
        
      case let .loadMoreCardsIfNeeded(displayingIndex):
        guard
          displayingIndex == state.dataSource.cardDetails.count - 1,
          state.dataSource.hasNextPage
        else {
          return .none
        }
        
        let nextQuery = state.queryType.next()
        
        return .run { [client] send in
          let result = try await client.queryCards(nextQuery)
          
          await send(
            .updateCards(
              result.data,
              hasNextPage: result.hasMore ?? false,
              queryType: nextQuery
            )
          )
        }
        .cancellable(
          id: "loadMoreCardsIfNeeded: \(displayingIndex), for query: \(state.queryType)",
          cancelInFlight: true
        )
        
      case let .updateCards(value, hasNextPage, nextQuery):
        switch state.mode {
        case .data:
          state.dataSource.append(cards: value)
          state.dataSource.hasNextPage = hasNextPage
          
          state.queryType = nextQuery
          
        case .placeholder:
          state.dataSource = QueryDataSource(
            queryType: nextQuery,
            cards: IdentifiedArray(uniqueElements: value),
            focusedCard: nil,
            hasNextPage: hasNextPage
          )
        }
        state.queryType = nextQuery
      
      state.mode = .data
      
      return .none
      
    case .viewAppeared:
      if state.mode.isPlaceholder {
        return .run { [client, queryType = state.queryType] send in
          let result = try await client.queryCards(queryType)
          
          await send(
            .updateCards(
              result.data,
              hasNextPage: result.hasMore ?? false,
              queryType: queryType
            )
          )
        }
        .cancellable(
          id: "viewAppeared: \(state.queryType)",
          cancelInFlight: true
        )
      } else {
        return .none
      }
    }
  }
}

public init() {}
}
