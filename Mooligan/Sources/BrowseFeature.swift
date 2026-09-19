import Browse
import ComposableArchitecture
import CardDetail
import Query
import ScryfallKit
import Networking
import Foundation
import CardScanner
import PackOpening

@Reducer
public struct Feature {
  @Reducer
  public enum Path {
    case showCardDetail(CardDetailFeature)
    case showCardPager(CardPagerFeature)
    case showSetDetail(QueryFeature)
  }
  
  public enum MenuItem: Equatable, CaseIterable, Identifiable {
    case sets
    case scan
    case collection
    case settings
    
    public var title: String {
      switch self {
      case .sets: return String(localized: "Sets")
      case .scan: return String(localized: "Scan")
      case .collection: return String(localized: "Collection")
      case .settings: return String(localized: "Settings")
      }
    }
    
    public var systemIconName: String {
      switch self {
      case .sets: return "text.page"
      case .scan: return "camera.fill"
      case .collection: return "folder"
      case .settings: return "gearshape"
      }
    }
    
    public nonisolated var id: Self { self }
  }
  
  @ObservableState
  public struct State: Equatable {
    public var sets: Browse.BrowseFeature.State
    public var bulkSync: BulkSyncFeature.State
    public var selectedSet: MTGSet?
    public var path: StackState<Path.State>
    public var isCollectionPresented = false
    
    @Presents public var scan: CardScannerFeature.State?
    @Presents public var settings: SettingsFeature.State?
    
    /// The pack currently being opened, presented over whatever set it came
    /// from.
    @Presents public var packSession: PackSessionFeature.State?
    
    public init(
      sets: Browse.BrowseFeature.State = .init(),
      bulkSync: BulkSyncFeature.State = .init(),
      selectedSet: MTGSet? = nil,
      path: StackState<Path.State> = .init()
    ) {
      self.sets = sets
      self.bulkSync = bulkSync
      self.selectedSet = selectedSet
      self.path = path
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    case setup
    case menuItemSelected(MenuItem)
    case sets(BrowseFeature.Action)
    case scan(PresentationAction<CardScannerFeature.Action>)
    case settings(PresentationAction<SettingsFeature.Action>)
    case packSession(PresentationAction<PackSessionFeature.Action>)
    case bulkSync(BulkSyncFeature.Action)
    case path(StackActionOf<Path>)
    case cardPagerStatePrepared(CardPagerFeature.State)
  }
  
  @Dependency(\.databasePreparer) private var databasePreparer
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Scope(state: \.sets, action: \.sets) {
      Browse.BrowseFeature()
    }
    
    Scope(state: \.bulkSync, action: \.bulkSync) {
      BulkSyncFeature()
    }
    
    Reduce(coreReduce)
      .forEach(\.path, action: \.path)
      .ifLet(\.$scan, action: \.scan) {
        CardScannerFeature()
      }
      .ifLet(\.$packSession, action: \.packSession) {
        PackSessionFeature()
      }
      .ifLet(\.$settings, action: \.settings) {
        SettingsFeature()
      }
  }
  
  public init() {}
  
  private func coreReduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding:
      return .none
      
    case .setup:
      // Both of these have to finish before launch does: the database so the
      // first screen does not read a blank one, and the background task because
      // `BGTaskScheduler` refuses a handler registered any later.
      databasePreparer.prepare()
      return .send(.bulkSync(.registerBackgroundTask))
      
    case let .menuItemSelected(item):
      switch item {
      case .sets:
        state.path.removeAll()
        
      case .scan:
        state.scan = CardScannerFeature.State()
        
      case .collection:
        state.isCollectionPresented = true

      case .settings:
        state.settings = SettingsFeature.State()
      }
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

    case .settings:
      return .none
      
    case .packSession(.presented(.delegate(.finished))):
      state.packSession = nil
      return .none
      
    case .packSession:
      return .none
      
    case .bulkSync:
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
          case let .didSelectOpenPack(set, kind):
            state.packSession = PackSessionFeature.State(
              product: PackProduct(set: set, kind: kind)
            )
            return .none
            
          case let .didSelectCard(card, queryType):
            guard
              case let .showSetDetail(queryState) = state.path[id: id]
            else {
              return .none
            }
            
            let cardDetails = queryState.dataSource.cardDetails
            return .run { send in
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

extension Feature.Path.State: Equatable {}
