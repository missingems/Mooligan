import ComposableArchitecture
import ScryfallKit
import DesignComponents
import Networking
import Foundation

private let kMinConfidenceDistance: Float = 0.35
private let kSameCardDistanceTolerance: Float = 0.08
private let kRequiredConfirmationCount: Int = 2

@Reducer public struct CardScannerFeature: Sendable {
  @Dependency(\.cardQueryRequestClient) var client
  @Dependency(\.cardImageHashSyncManager) var imageHashManager
  
  private enum CancelID { case networkQuery }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
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
        
        // 1. Nothing found — bail
        guard let topMatch = matches.first else {
          state.pendingMatchID = nil
          state.pendingMatchCount = 0
          return .none
        }
        
        // 3. Already queried this card — ignore until something new shows up
        if state.lastQueriedMatchID == topMatch.id {
          state.pendingMatchCount += 1
          return .none
        }
        
        // 4. Old winner still lurking in the result set — likely drift, not a new card
        if let lastQueriedID = state.lastQueriedMatchID,
           matches.prefix(3).contains(where: { $0.id == lastQueriedID }) {
          state.pendingMatchCount += 1
          return .none
        }
        
        // 5. Accumulate — same card as our pending candidate?
        if state.pendingMatchID == topMatch.id {
          state.pendingMatchCount += 1
        } else {
          // Different card — reset the counter to 1
          state.pendingMatchID = topMatch.id
          state.pendingMatchCount = 1
          state.lastTopMatchDistance = topMatch.distance
          return .none
        }
        
        // 6. Not enough confirmations yet
        guard state.pendingMatchCount >= kRequiredConfirmationCount else {
          return .none
        }
        
        // 7. Confirmed — commit and query
        state.lastQueriedMatchID = topMatch.id
        state.lastTopMatchDistance = topMatch.distance
        state.pendingMatchID = nil
        state.pendingMatchCount = 0
        
        let matchIDs = [matches.map(\.id).first!]
        print("Querying confirmed card: \(topMatch.id) after \(kRequiredConfirmationCount) confirmations")
        
        return .run { send in
          let result = try await client.queryCards(matchIDs).data
          await send(.updateMatches(CardDataSource(cards: result, hasNextPage: false, total: result.count)))
        } catch: { error, send in
          print("Scryfall query failed: \(error)")
        }
          .cancellable(id: CancelID.networkQuery, cancelInFlight: true)
        
      case let .updateMatches(result):
        state.dataSource = result
        return .none
        
      case .syncCardImageHashDatabase:
        return .run { _ in
          await imageHashManager.sync()
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
    
    /// The card ID of the last card we actually sent to Scryfall
    var lastQueriedMatchID: String? = nil
    /// The VNFeaturePrint distance of the last committed match
    var lastTopMatchDistance: Float = 1.0
    /// The card ID we're accumulating confirmations for (not yet queried)
    var pendingMatchID: String? = nil
    /// How many consecutive frames have seen pendingMatchID as the top match
    var pendingMatchCount: Int = 0
    /// Busy-lock: prevents processing a new frame while one is already in flight
    var isProcessingFrame: Bool = false
    
    public init(scannedResult: OCRCardScannedResult?) {
      self.scannedResult = scannedResult
    }
  }
  
  enum Action: Sendable {
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

// MARK: - Action Equatable

extension CardScannerFeature.Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.didScan(l), .didScan(r)):
      return l == r
    case let (.internalMatchesFound(l), .internalMatchesFound(r)):
      return l.map(\.id) == r.map(\.id)
    case let (.updateMatches(l), .updateMatches(r)):
      return l == r
    case (.syncCardImageHashDatabase, .syncCardImageHashDatabase):
      return true
    default:
      return false
    }
  }
}
