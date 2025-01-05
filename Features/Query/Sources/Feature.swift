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
    @Shared var dataSource: QueryDataSource
    
    public init(
      mode: Mode,
      queryType: QueryType
    ) {
      self.mode = mode
      self.queryType = queryType
      
      self._dataSource = Shared(value: QueryDataSource(queryType: queryType, cards: IdentifiedArray(
        uniqueElements: MockCardDetailRequestClient.generateMockCards(
          number: 10
        )
      ), focusedCard: nil, hasNextPage: false))
    }
  }
  
  public enum Action: Equatable {
    case didSelectCard(Card)
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards([Card], hasNextPage: Bool, queryType: QueryType)
    case routeToCardDetail(Shared<QueryDataSource>)
    case viewAppeared
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .routeToCardDetail:
        return .none
        
      case let .didSelectCard(value):
        return .run { [dataSource = state.$dataSource] send in
          dataSource.withLock { _value in
            _value.focusedCard = value
          }
          await send(.routeToCardDetail(dataSource))
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
          state.$dataSource.withLock { data in
            data.append(cards: value)
            data.hasNextPage = hasNextPage
          }
          
          state.queryType = nextQuery
          
        case .placeholder:
          state.$dataSource.withLock { _value in
            _value = QueryDataSource(
              queryType: nextQuery,
              cards: IdentifiedArray(uniqueElements: value),
              focusedCard: nil,
              hasNextPage: hasNextPage
            )
          }
          state.queryType = nextQuery
        }
        
        state.mode = .data
        
        return .none
        
      case .viewAppeared:
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
      }
    }
  }
  
  public init() {}
}
