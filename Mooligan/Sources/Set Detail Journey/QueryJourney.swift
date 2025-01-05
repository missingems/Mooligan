import Browse
import ComposableArchitecture
import CardDetail
import Query
import ScryfallKit
import Networking

@Reducer struct QueryJourney {
  @Reducer enum Path {
    case cardDetailsPageView(CardDetail.PageFeature)
  }
  
  @ObservableState struct State {
    @Shared var dataSource: QueryDataSource
    var path = StackState<Path.State>()
  }
  
  enum Action {
    case cardDetails(Query.Feature.Action)
    case path(StackActionOf<Path>)
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .cardDetails(_):
        return .none
      case .path(_):
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}
