import Browse
import ComposableArchitecture
import CardDetail
import Query
import ScryfallKit
import Networking
import Foundation

@Reducer enum Path {
  case showCardDetail(CardDetailFeature)
  case showSetDetail(QueryFeature)
  case showVariantGalleryFeatureFromVariantGrid(VariantGalleryFeature)
  case showVariantGalleryFeatureFromMainImage(VariantGalleryFeature)
}

@Reducer struct Feature {
  enum TabInfo: Equatable, CaseIterable, Identifiable {
    case sets
    case search
    case game
    case collection
    case settings
    
    var title: String {
      switch self {
      case .search:
        return String(localized: "Search")
      case .sets:
        return String(localized: "Sets")
      case .game:
        return String(localized: "Game")
      case .collection:
        return String(localized: "Collection")
      case .settings:
        return String(localized: "Settings")
      }
    }
    
    var systemIconName: String {
      switch self {
      case .search:
        return "magnifyingglass.circle"
      case .sets:
        return "text.page"
      case .game:
        return "dice"
      case .collection:
        return "folder"
      case .settings:
        return "gearshape"
      }
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
              Query.QueryFeature.State(
                mode: .placeholder,
                queryType: .querySet(
                  value,
                  SearchQuery(setCode: value.code, page: 1, sortMode: .name, sortDirection: .auto)
                )
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
            case .binding:
              break
              
            case .didSelectShowInfo:
              break
              
            case .didSelectShowSortOptions:
              break
              
            case let .didSelectCard(card, queryType):
              state.path.append(.showCardDetail(CardDetailFeature.State(card: card, queryType: queryType)))
              
            case .loadMoreCardsIfNeeded(displayingIndex: let displayingIndex):
              break
              
            case .updateCards(_, _, _):
              break
              
            case .viewAppeared:
              break
              
            case .scrollToTop:
              break
            }
            
          case let .showCardDetail(value):
            switch value {
            case let .didSelectVariant(card, id):
              state.path.append(
                .showVariantGalleryFeatureFromVariantGrid(
                  VariantGalleryFeature.State(selectedCard: card, id: id)
                )
              )
              
            case let .didSelectCardDetailImage(card, id):
              state.path.append(
                .showVariantGalleryFeatureFromMainImage(
                  VariantGalleryFeature.State(selectedCard: card, id: id)
                )
              )
              
            default:
              break
            }
            
          case .showVariantGalleryFeatureFromVariantGrid, .showVariantGalleryFeatureFromMainImage:
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
