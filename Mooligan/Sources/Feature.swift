import Browse
import ComposableArchitecture
import Query
import ScryfallKit

@Reducer struct Feature {
  enum TabInfo: Equatable, CaseIterable, Identifiable {
    case sets
    
    var title: String {
      return String(localized: "Sets")
    }
    
    var systemIconName: String {
      return "text.page"
    }
    
    nonisolated(unsafe) var id: Self {
      return self
    }
  }
  
  @ObservableState struct State {
    var sets: Browse.Feature.State = .init(selectedSet: nil, sets: [])
    var path = StackState<Path.State>()
  }
  
  @Reducer enum Path {
    case showSetDetail(Query.Feature)
  }
  
  enum Action {
    case sets(Browse.Feature.Action)
    case path(StackActionOf<Path>)
  }
  
  var body: some ReducerOf<Self> {
    Scope(state: \.sets, action: \.sets) {
      Browse.Feature()
    }
    
    Reduce { state, action in
      switch action {
      case let .sets(action):
        if case let .didSelectSet(value) = action {
          state.path.append(
            .showSetDetail(
              Query.Feature.State(
                mode: .placeholder(numberOfDataSource: value.cardCount),
                queryType: .set(value, page: 1),
                selectedCard: nil
              )
            )
          )
        }
        
        return .none
        
      default:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}
