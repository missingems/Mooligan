import ComposableArchitecture
import Networking

@Reducer
struct Feature<Client: MagicCardQueryRequestClient> {
  let client: Client
  
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
    case didSelectCard(Client.MagicCardModel)
    case loadMoreCardsIfNeeded(currentIndex: Int)
    case showError(title: String, description: String)
    case updateCards(ObjectList<[Client.MagicCardModel]>, QueryType)
    case viewAppeared
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didSelectCard(value):
        return .none
        
      case let .loadMoreCardsIfNeeded(currentIndex):
        let nextQuery = state.queryType.next()
        
        return if state.dataSource.shouldFetchNextPage(at: currentIndex) {
          fetchCardsEffect(queryType: nextQuery)
        } else {
          .none
        }
        
      case let .showError(title, description):
        return .none
      
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
  }
}

extension Feature {
  func updateCardsEffect(
    value: ObjectList<[Client.MagicCardModel]>,
    queryType: QueryType,
    state: inout State
  ) -> Effect<Action> {
    state.queryType = queryType
    state.dataSource.model.append(contentsOf: value.model)
    state.dataSource.hasNextPage = value.hasNextPage
    
    return .none
  }
  
  func fetchCardsEffect(queryType: QueryType) -> Effect<Action> {
    .run { [client] send in
      do {
        try await send(
          .updateCards(
            client.queryCards(queryType),
            queryType
          )
        )
      } catch {
        await send(
          .showError(
            title: String(localized: "Something went wrong"),
            description: error.localizedDescription
          )
        )
      }
    }
    .cancellable(
      id: Cancellables.queryCards(page: queryType.page),
      cancelInFlight: true
    )
  }
}
