import ComposableArchitecture
import ScryfallKit
import Networking

@Reducer
struct Feature {
  @Dependency(\.cardQueryRequestClient) var client
  
  @ObservableState
  struct State: Equatable {
    var dataSource: DataSource
    var queryType: QueryType
    var selectedCard: Card?
    
    init(
      dataSource: DataSource,
      queryType: QueryType,
      selectedCard: Card?
    ) {
      self.dataSource = dataSource
      self.queryType = queryType
      self.selectedCard = selectedCard
    }
  }
  
  enum Action: Equatable {
    case didSelectCard(Card)
    case loadMoreCardsIfNeeded(displayingIndex: Int)
    case updateCards([Card], hasNextPage: Bool, queryType: QueryType)
    case viewAppeared
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didSelectCard(value):
        state.selectedCard = value
        return .none
        
      case let .loadMoreCardsIfNeeded(displayingIndex):
        guard
          displayingIndex == state.dataSource.cards.count - 1,
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
        var dataSource = state.dataSource
        dataSource.cards.append(contentsOf: value)
        dataSource.hasNextPage = hasNextPage
        state.dataSource = dataSource
        state.queryType = nextQuery
        
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
}

extension Feature {
  struct DataSource: Equatable {
    var cards: IdentifiedArrayOf<Card>
    var hasNextPage: Bool
    
    init(cards: IdentifiedArrayOf<Card>, hasNextPage: Bool) {
      self.cards = cards
      self.hasNextPage = hasNextPage
    }
  }
}
