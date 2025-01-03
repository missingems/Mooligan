import Browse
import ComposableArchitecture
import CardDetail
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
    var sets: Browse.Feature.State
    var selectedSet: MTGSet?
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
          state.selectedSet = value
          
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
        
      case let .path(value):
        switch value {
        case .element(id: let id, action: let action):
          switch action {
          case let .showSetDetail(value):
            switch value {
            case let .didSelectCard(card):
              break
              
            case .loadMoreCardsIfNeeded(displayingIndex: let displayingIndex):
              break
              
            case .updateCards(_, hasNextPage: let hasNextPage, queryType: let queryType):
              break
              
            case .viewAppeared:
              break
            }
          }
        case .popFrom(id: let id):
          break
        case .push(id: let id, state: let state):
          break
        }
        
        return .none
      }
    }
    .forEach(\.path, action: \.path)
    ._printChanges(.actionLabels)
  }
}
