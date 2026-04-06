import ComposableArchitecture
import ScryfallKit
import DesignComponents
import Networking
import Foundation

private let kMinConfidenceDistance: Float = 0.35
private let kSameCardDistanceTolerance: Float = 0.08
private let kRequiredConfirmationCount: Int = 3

@Reducer public struct CardScannerFeature: Sendable {
  @Dependency(\.cardQueryRequestClient) var client
  @Dependency(\.cardImageHashSyncManager) var imageHashManager
  
  private enum CancelID { case networkQuery }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding:
        // We no longer need to manually intercept and update the scrolled card
        // because we made it a computed property in the State below.
        return .none
        
      case let .didScan(result):
        guard !state.isProcessingFrame else {
          return .none
        }
        
        state.isProcessingFrame = true
        
        return .run { send in
          let bestMatches = await imageHashManager.findBestMatches(for: result.value)
            .map { (id: $0.id, distance: $0.distance) }
          await send(.internalMatchesFound(bestMatches))
        }
        
      case let .internalMatchesFound(matches):
        state.isProcessingFrame = false
        
        guard let topMatch = matches.first else {
          state.pendingMatchID = nil
          state.pendingMatchCount = 0
          return .none
        }
        
        if state.lastQueriedMatchID == topMatch.id {
          state.pendingMatchCount += 1
          return .none
        }
        
        if let lastQueriedID = state.lastQueriedMatchID,
           matches.prefix(3).contains(where: { $0.id == lastQueriedID }) {
          state.pendingMatchCount += 1
          return .none
        }
        
        if state.pendingMatchID == topMatch.id {
          state.pendingMatchCount += 1
        } else {
          state.pendingMatchID = topMatch.id
          state.pendingMatchCount = 1
          state.lastTopMatchDistance = topMatch.distance
          return .none
        }
        
        guard state.pendingMatchCount >= kRequiredConfirmationCount else {
          return .none
        }
        
        state.lastQueriedMatchID = topMatch.id
        state.lastTopMatchDistance = topMatch.distance
        state.pendingMatchID = nil
        state.pendingMatchCount = 0
        
        if let value = matches.first?.id {
          return .run { send in
            let result = try await client.queryCards(for: value).data
            await send(.updateMatches(CardDataSource(cards: result, hasNextPage: false, total: result.count)))
          } catch: { error, send in
            print("Scryfall query failed: \(error)")
          }.cancellable(id: CancelID.networkQuery, cancelInFlight: true)
        } else {
          return .none
        }
        
      case let .updateMatches(result):
        state.dataSource = result
        
        if let firstCardID = result.cardDetails.first?.card.id {
          state.scrolledCardID = firstCardID
        }
        
        return .none
        
      case .syncCardImageHashDatabase:
        return .run { send in
          await imageHashManager.sync()
          let a: (String, Float) = (id: "83293ff4-0841-4f5e-8d59-1ae29a62c890", distance: 0.0)
          await send(.internalMatchesFound([a]))
          await send(.internalMatchesFound([a]))
          await send(.internalMatchesFound([a]))
        }
      }
    }
  }
  
  public init() {}
}

// MARK: - State, Action, SyncStatus

public extension CardScannerFeature {
  @ObservableState struct State: Sendable, Equatable {
    var scannedResult: OCRCardScannedResult?
    var dataSource: CardDataSource?
    var queryWithSetCode: SearchQuery?
    var queryWithoutSetCode: SearchQuery?
    
    // The ID bound to the ScrollView
    var scrolledCardID: UUID?
    
    // 💡 FIX: Make scrolledCard a computed property!
    // It will now safely and automatically derive the correct card the exact millisecond the user scrolls.
    var scrolledCard: Card? {
      guard let id = scrolledCardID, let details = dataSource?.cardDetails else { return nil }
      return details.first(where: { $0.card.id == id })?.card
    }
    
    var lastQueriedMatchID: String? = nil
    var lastTopMatchDistance: Float = 1.0
    var pendingMatchID: String? = nil
    var pendingMatchCount: Int = 0
    var isProcessingFrame: Bool = false
    
    public init(scannedResult: OCRCardScannedResult?) {
      self.scannedResult = scannedResult
    }
  }
  
  enum Action: Sendable, BindableAction {
    case binding(BindingAction<State>)
    case didScan(ScannedImage)
    case internalMatchesFound([(id: String, distance: Float)])
    case updateMatches(CardDataSource)
    case syncCardImageHashDatabase
  }
  
  enum SyncStatus: Equatable, Sendable {
    case syncing
    case checkingForUpdates
    case synced
    case syncedFailure
  }
}
