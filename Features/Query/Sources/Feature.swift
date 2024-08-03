import ComposableArchitecture
import Networking

@Reducer
struct Feature<Client: MagicCardQueryRequestClient> {
  let client: UnsafeSendable<Client>
  
  enum Cancellables: Hashable {
    case queryCards(page: Int)
  }
  
  @ObservableState
  struct State: Equatable {
    var queryType: QueryType
    var dataSource = ObjectList<[Client.MagicCardModel]>(model: [])
    
    mutating func update(
      with queryType: QueryType,
      dataSource: ObjectList<[Client.MagicCardModel]>
    ) {
      self.queryType = queryType
      self.dataSource = dataSource
    }
  }
  
  enum Action: Equatable {
    case didSelectCardAtIndex(Int)
    case loadMoreCardsIfNeeded(currentIndex: Int)
    case updateCards(ObjectList<[Client.MagicCardModel]>, QueryType)
    case viewAppeared
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didSelectCardAtIndex(value):
        return .none
        
      case let .loadMoreCardsIfNeeded(currentIndex):
        return if state.dataSource.shouldFetchNextPage(at: currentIndex) {
          fetchCardsEffect(queryType: state.queryType).cancellable(
            id: Cancellables.queryCards(page: state.queryType.next().page),
            cancelInFlight: false
          )
        } else {
          .none
        }
      
      case let .updateCards(value, queryType):
        return updateCardsEffect(
          value: value,
          queryType: queryType,
          state: &state
        )
        
      case .viewAppeared:
        return fetchCardsEffect(queryType: state.queryType)
      }
    }
    ._printChanges(.actionLabels)
  }
}

extension Feature {
  func updateCardsEffect(
    value: ObjectList<[Client.MagicCardModel]>,
    queryType: QueryType,
    state: inout State
  ) -> Effect<Action> {
    defer {
      state.queryType = queryType
      state.dataSource.model.append(contentsOf: value.model)
      state.dataSource.hasNextPage = value.hasNextPage
    }
    
    return .none
  }
  
  func fetchCardsEffect(queryType: QueryType) -> Effect<Action> {
    .run { [client] send in
      try await send(
        .updateCards(
          client.wrappedValue.queryCards(queryType),
          queryType
        )
      )
    }
  }
}
