import Foundation
import UIKit
import ComposableArchitecture
import Nuke
import DesignComponents
import ScryfallKit
import Networking

// MARK: - Constants

private enum ScannerConstants {
  static let requiredMatchFrames = 3
  static let maxRecentMatchIDs   = 3
  static let morphDurationNanos: UInt64 = 600_000_000
}

// MARK: - Scanner Status

public enum ScannerStatus: Equatable, Sendable {
  case loading
  case scanning
  case scanFound
  case cardDetails(title: String, subtitle: String)
  
  public var displayTitle: String {
    switch self {
    case .loading:                    return "Loading..."
    case .scanning:                   return "Scanning..."
    case .scanFound:                  return "Scan Found!"
    case let .cardDetails(title, _):  return title
    }
  }
}

// MARK: - Reducer

@Reducer public struct CardScannerFeature: Sendable {
  
  @ObservableState
  public struct State: Sendable, Equatable {
    public var status: ScannerStatus = .loading
    public var dataSource: CardDataSource?
    public var latestTrackedCorners: QuadCorners? = nil
    public var isMorphed: Bool = false
    public var isMorphAnimationComplete: Bool = false
    public var isScanningPaused: Bool = false
    public var isProcessingFrame: Bool = false
    public var recentMatchIDs: [String] = []
    public var viewSize: CGSize? = nil
    public var topSafeArea: CGFloat = 0
    public var bottomSafeArea: CGFloat = 0
    
    // FIX: removed scannedResult, queryWithSetCode, queryWithoutSetCode —
    // all three were declared but never read or written in the reducer,
    // adding dead weight to every Equatable comparison.
    public init() {}
  }
  
  public enum Action: Sendable, BindableAction {
    case binding(BindingAction<State>)
    case trackingCornersUpdated(QuadCorners?)
    case didScan(ScannedImage)
    case internalMatchesFound([(id: String, distance: Float)])
    case singleCardFound(Card)
    case fetchVariants(Card)
    case variantsLoaded([Card])
    case syncCardImageHashDatabase
    case syncCompleted
    // FIX: removed imageDownloadCompleted — it was a single-line Effect.run that
    // immediately dispatched triggerMorph, adding an unnecessary async hop and a
    // second cancellable registration for no benefit.
    // FIX: triggerMorph no longer carries an associated Card — the value was always
    // discarded in the case body, then re-derived from state in morphAnimationFinished.
    case triggerMorph
    case morphAnimationFinished
    case resetScan
    case updateViewSize(CGSize)
    case updateSafeAreas(top: CGFloat, bottom: CGFloat)
  }
  
  @Dependency(\.cardQueryRequestClient) var client
  @Dependency(\.cardImageHashSyncManager) var imageHashManager
  
  private enum CancelID {
    case networkQuery
    case imageDownload
    case variantsQuery
    case delayedMorph
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce(coreReduce)
  }
  
  private func coreReduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
      
    case .binding, .updateSafeAreas:
      return .none
      
    case let .trackingCornersUpdated(corners):
      // FIX: was lumped into the .none group — latestTrackedCorners was never
      // written, so the morph animation had no source position to animate from.
      // Guard on isMorphed so mid-bounce frames don't jitter the source position.
      if !state.isMorphed {
        state.latestTrackedCorners = corners
      }
      return .none
      
    case let .updateViewSize(size):
      if state.viewSize != size {
        state.viewSize = size
      }
      return .none
      
    case .resetScan:
      state.isMorphed = false
      state.isMorphAnimationComplete = false
      state.dataSource = nil
      state.isProcessingFrame = false
      state.status = .scanning
      state.isScanningPaused = false
      state.latestTrackedCorners = nil
      state.recentMatchIDs.removeAll()
      
      return .merge(
        .cancel(id: CancelID.networkQuery),
        .cancel(id: CancelID.imageDownload),
        .cancel(id: CancelID.variantsQuery),
        .cancel(id: CancelID.delayedMorph)
      )
      
    case let .didScan(result):
      guard !state.isScanningPaused, state.dataSource == nil, !state.isProcessingFrame else { return .none }
      state.isProcessingFrame = true
      let img = result.value
      
      return .run { send in
        let matches = await imageHashManager.findBestMatches(for: img)
        let mappedMatches = matches.map { (id: $0.id, distance: $0.distance) }
        await send(.internalMatchesFound(mappedMatches))
      }
      
    case let .internalMatchesFound(matches):
      state.isProcessingFrame = false
      guard !state.isScanningPaused else { return .none }
      
      guard let topMatch = matches.first else {
        if state.dataSource == nil { state.status = .scanning }
        state.recentMatchIDs.removeAll()
        return .none
      }
      
      // FIX: removed redundant `|| state.recentMatchIDs.isEmpty` — when empty,
      // `.last` is nil which never equals a String, so the else branch already
      // produces the same outcome (recentMatchIDs = [topMatch.id]).
      // FIX: cap the array at maxRecentMatchIDs to prevent unbounded growth.
      if state.recentMatchIDs.last == topMatch.id {
        if state.recentMatchIDs.count < ScannerConstants.maxRecentMatchIDs {
          state.recentMatchIDs.append(topMatch.id)
        }
      } else {
        state.recentMatchIDs = [topMatch.id]
      }
      
      guard state.recentMatchIDs.count >= ScannerConstants.requiredMatchFrames else { return .none }
      
      if state.dataSource == nil { state.status = .scanFound }
      state.isScanningPaused = true
      
      return .run { send in
        let card = try await client.queryCard(for: topMatch.id)
        await send(.singleCardFound(card))
      } catch: { _, send in
        await send(.resetScan)
      }.cancellable(id: CancelID.networkQuery, cancelInFlight: true)
      
    case let .singleCardFound(card):
      state.status = .cardDetails(title: card.name, subtitle: "\(card.setName) • #\(card.collectorNumber)")
      state.dataSource = CardDataSource(cards: [card], hasNextPage: false, total: 1)
      
      // FIX: dispatches triggerMorph directly — the old imageDownloadCompleted
      // action was an unnecessary relay. Image download failure now falls through
      // to triggerMorph gracefully via try? instead of a nested do/catch.
      return .run { send in
        if let urlString = card.imageUris?.normal, let url = URL(string: urlString) {
          var processors: [any ImageProcessing] = []
          if card.isLandscape { processors.append(RotationImageProcessor(degrees: 90)) }
          let request = ImageRequest(url: url, processors: processors)
          try? await ImagePipeline.shared.image(for: request)
        }
        await send(.triggerMorph)
      }.cancellable(id: CancelID.imageDownload, cancelInFlight: true)
      
    case .triggerMorph:
      state.isMorphed = true
      return .run { send in
        try await Task.sleep(nanoseconds: ScannerConstants.morphDurationNanos)
        await send(.morphAnimationFinished)
      }.cancellable(id: CancelID.delayedMorph, cancelInFlight: true)
      
    case .morphAnimationFinished:
      state.isMorphAnimationComplete = true
      guard let card = state.dataSource?.cardDetails.first?.card else { return .none }
      return .run { send in
        await send(.fetchVariants(card))
      }.cancellable(id: CancelID.variantsQuery, cancelInFlight: true)
      
    case let .fetchVariants(card):
      let query = SearchQuery(oracleID: card.oracleId, page: 1, sortMode: .released, sortDirection: .auto)
      return .run { send in
        let data = try await client.queryCards(query).data
        await send(.variantsLoaded(data), animation: .default)
      } catch: { _, _ in
      }.cancellable(id: CancelID.variantsQuery, cancelInFlight: true)
      
    case let .variantsLoaded(variants):
      guard let currentCard = state.dataSource?.cardDetails.first?.card else { return .none }
      var updatedCards = variants
      if let index = updatedCards.firstIndex(where: { $0.id == currentCard.id }) {
        updatedCards.remove(at: index)
      }
      updatedCards.insert(currentCard, at: 0)
      state.dataSource = CardDataSource(cards: updatedCards, hasNextPage: false, total: updatedCards.count)
      return .none
      
    case .syncCardImageHashDatabase:
      return .run { send in
        await imageHashManager.sync()
        await send(.syncCompleted)
      }
      
    case .syncCompleted:
      state.status = .scanning
      return .none
    }
  }
  
  public init() {}
}
