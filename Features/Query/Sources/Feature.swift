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
    var dataSource: QueryDataSource?
    var testdataSource: [(Range<Array<CardInfo>.Index>.Element, CardInfo)] = []
    
    public init(
      mode: Mode,
      queryType: QueryType
    ) {
      self.mode = mode
      self.queryType = queryType
    }
  }
  
  public enum Action: Equatable {
    case didSelectCard(Card)
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards(QueryDataSource?, QueryType)
    case routeToCardDetail(QueryDataSource?)
    case viewAppeared
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .routeToCardDetail:
        return .none
        
      case .didSelectCard:
        return .run { [dataSource = state.dataSource] send in
          await send(.routeToCardDetail(nil))
        }
        
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
          
          await send(.updateCards(dataSource, nextQuery))
        }
        .cancellable(
          id: "loadMoreCardsIfNeeded: \(displayingIndex), for query: \(state.queryType)",
          cancelInFlight: true
        )
        
      case let .updateCards(value, nextQuery):
        if let value {
          state.dataSource = value
          state.queryType = nextQuery
          
          state.testdataSource = Array(zip(state.dataSource!.cardDetails.indices, state.dataSource!.cardDetails))
          state.mode = .data
        }
        
//        a        return .none
        return .none
        
      case .viewAppeared:
        if state.mode.isPlaceholder {
          return .run { [client, queryType = state.queryType] send in
            let result = try await client.queryCards(queryType)
            let dataSource = QueryDataSource(queryType: queryType, cards: result.data, focusedCard: nil, hasNextPage: result.hasMore ?? false)
            await send(.updateCards(dataSource, queryType))
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
