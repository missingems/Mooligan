import Browse
import ComposableArchitecture
import CardDetail
import Query
import ScryfallKit
import Networking
import Foundation
import CardScanner

@Reducer
public struct Feature {
  @Reducer
  public enum Path {
    case showCardDetail(CardDetailFeature)
    case showCardPager(CardPagerFeature)
    case showSetDetail(QueryFeature)
  }
  
  public enum TabInfo: Equatable, CaseIterable, Identifiable {
    case sets
    case scan
    case collection
    
    public var title: String {
      switch self {
      case .sets: return String(localized: "Sets")
      case .scan: return String(localized: "Scan")
      case .collection: return String(localized: "Collection")
      }
    }
    
    public var systemIconName: String {
      switch self {
      case .sets: return "text.page"
      case .scan: return "camera.fill"
      case .collection: return "folder"
      }
    }
    
    public nonisolated var id: Self { self }
  }
  
  @ObservableState
  public struct State {
    public var selectedTab: TabInfo = .sets
    public var sets: Browse.BrowseFeature.State
    public var scan: CardScannerFeature.State
    public var selectedSet: MTGSet?
    public var path: StackState<Path.State>
    
    public init(
      selectedTab: TabInfo = .sets,
      sets: Browse.BrowseFeature.State = .init(),
      scan: CardScannerFeature.State = .init(),
      selectedSet: MTGSet? = nil,
      path: StackState<Path.State> = .init()
    ) {
      self.selectedTab = selectedTab
      self.sets = sets
      self.scan = scan
      self.selectedSet = selectedSet
      self.path = path
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case sets(Browse.BrowseFeature.Action)
    case scan(CardScannerFeature.Action)
    case path(StackActionOf<Path>)
    case cardPagerStatePrepared(CardPagerFeature.State)
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Scope(state: \.sets, action: \.sets) {
      Browse.BrowseFeature()
    }
    
    Scope(state: \.scan, action: \.scan) {
      CardScannerFeature()
    }
    
    Reduce(coreReduce)
      .forEach(\.path, action: \.path)
  }
  
  public init() {}
  
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
      
    case let .cardPagerStatePrepared(pagerState):
      state.path.append(.showCardPager(pagerState))
      return .none
      
    case let .path(value):
      switch value {
      case let .element(id, action):
        switch action {
        case let .showSetDetail(value):
          switch value {
          case let .didSelectCard(card, queryType):
            guard
              case let .showSetDetail(queryState) = state.path[id: id],
              let dataSource = queryState.dataSource
            else {
              return .none
            }
            
            let cardDetails = dataSource.cardDetails
            return .run { send in
              // Pass the full cardDetails to retain the flip states
              let pagerState = CardPagerFeature.State(
                cardDetails: cardDetails,
                initialSelectedCard: card,
                queryType: queryType
              )
              await send(.cardPagerStatePrepared(pagerState))
            }
            
          default:
            break
          }
          
        case .showCardPager:
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
