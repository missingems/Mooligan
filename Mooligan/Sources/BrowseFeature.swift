import Browse
import ComposableArchitecture
import CardDetail
import Query
import ScryfallKit
import Networking
import Foundation
import CardScanner

@Reducer enum Path {
  case showCardDetail(CardDetailFeature)
  case showCardPager(CardPagerFeature)
  case showSetDetail(QueryFeature)
}

@Reducer struct Feature {
  enum TabInfo: Equatable, CaseIterable, Identifiable {
    case sets
    case scan
    case collection
    
    var title: String {
      switch self {
      case .sets:
        return String(localized: "Sets")
        
      case .scan:
        return String(localized: "Scan")
        
      case .collection:
        return String(localized: "Collection")
      }
    }
    
    var systemIconName: String {
      switch self {
      case .sets:
        return "text.page"
        
      case .scan:
        return "camera.fill"
        
      case .collection:
        return "folder"
      }
    }
    
    nonisolated var id: Self {
      return self
    }
  }
  
  @ObservableState struct State {
    var selectedTab: TabInfo = .sets // 1. Added selection state
    var sets: Browse.BrowseFeature.State
    var scan: CardScannerFeature.State
    var selectedSet: MTGSet?
    var path = StackState<Path.State>()
  }
  
  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case sets(Browse.BrowseFeature.Action)
    case scan(CardScannerFeature.Action)
    case path(StackActionOf<Path>)
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    
    Scope(state: \.sets, action: \.sets) {
      BindingReducer()
      Browse.BrowseFeature()
    }
    
    Scope(state: \.scan, action: \.scan) {
      CardScannerFeature()
    }
    
    // 1. Pass the function into Reduce, and attach .forEach here in the body!
    Reduce(coreReduce)
      .forEach(\.path, action: \.path)
  }
  
  private func coreReduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding:
      return .none
      
    case let .sets(action):
      if case let .didSelectSet(value) = action {
        state.selectedSet = value
        
        state.path.append(
          .showSetDetail(
            Query.QueryFeature.State(
              mode: .placeholder,
              queryType: .querySet(
                value,
                SearchQuery(setCode: value.code, page: 1, sortMode: .name, sortDirection: .asc)
              )
            )
          )
        )
      }
      
      return .none
      
    case .scan:
      return .none
      
    case let .path(value):
      switch value {
      case let .element(id, action):
        switch action {
        case let .showSetDetail(value):
          switch value {
          case .binding:
            break
            
          case .didSelectShowInfo:
            break
            
          case let .didSelectCard(card, queryType):
            guard
              case let .showSetDetail(queryState) = state.path[id: id],
              let dataSource = queryState.dataSource
            else {
              return .none
            }
            
            let pagerState = CardPagerFeature.State(
              cards: dataSource.cardDetails.map(\.card),
              initialSelectedCard: card,
              queryType: queryType
            )
            
            state.path.append(.showCardPager(pagerState))
            return .none
            
          case .loadMoreCardsIfNeeded:
            break
            
          case .updateCards(_, _, _):
            break
            
          case .viewAppeared:
            break
            
          case .scrollToTop:
            break
          }
          
        case let .showCardPager(value):
          break
          
        case let .showCardDetail(value):
          switch value {
          case let .didSelectVariant(card, queryType):
            state.path.append(
              .showCardDetail(CardDetailFeature.State(card: card, queryType: queryType))
            )
            
          default:
            break
          }
        }
        
      case .popFrom:
        break
        
      case .push:
        break
      }
      
      return .none
    }
  }
}
