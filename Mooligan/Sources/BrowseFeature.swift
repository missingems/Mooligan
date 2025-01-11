import Browse
import ComposableArchitecture
import CardDetail
import Query
import ScryfallKit

@Reducer enum Path {
  case showCardDetail(CardDetail.CardDetailFeature)
  case showSetDetail(Query.Feature)
}

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
    var sets: Browse.BrowseFeature.State
    var selectedSet: MTGSet?
    var path = StackState<Path.State>()
  }
  
  enum Action {
    case sets(Browse.BrowseFeature.Action)
    case path(StackActionOf<Path>)
  }
  
  var body: some ReducerOf<Self> {
    Scope(state: \.sets, action: \.sets) {
      Browse.BrowseFeature()
    }
    
    Reduce { state, action in
      switch action {
      case let .sets(action):
        if case let .didSelectSet(value) = action {
          state.selectedSet = value
          
          state.path.append(
            .showSetDetail(
              Query.Feature.State(mode: .placeholder(numberOfDataSource: 10), queryType: .set(value, page: 1))
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
            case let .didSelectCard(card, queryType):
              state.path.append(.showCardDetail(CardDetailFeature.State(card: card, queryType: queryType)))
              
            case .loadMoreCardsIfNeeded(displayingIndex: let displayingIndex):
              break
              
            case .updateCards(_, _):
              break
              
            case .viewAppeared:
              break
            }
            
          case let .showCardDetail(value):
            break
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
