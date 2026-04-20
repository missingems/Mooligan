import Foundation
import UIKit
import ComposableArchitecture
import Nuke
import DesignComponents
import ScryfallKit
import Networking

// MARK: - Reducer & Status

public enum ScannerStatus: Equatable, Sendable {
  case loading
  case scanning
  case scanFound
  case cardDetails(title: String, subtitle: String)
  
  public var displayTitle: String {
    switch self {
    case .loading: return "Loading..."
    case .scanning: return "Scanning..."
    case .scanFound: return "Scan Found!"
    case let .cardDetails(title, _): return title
    }
  }
}

@Reducer public struct CardScannerFeature: Sendable {
  @ObservableState
  public struct State: Sendable, Equatable {
    public var status: ScannerStatus = .loading
    
    public var scannedResult: OCRCardScannedResult?
    public var dataSource: CardDataSource?
    public var queryWithSetCode: SearchQuery?
    public var queryWithoutSetCode: SearchQuery?
    
    // UI layout tracking + Morph Image
    public var latestTrackedCorners: QuadCorners? = nil
    public var isMorphed: Bool = false
    public var isMorphAnimationComplete: Bool = false
    public var isScanningPaused: Bool = false
    
    // Tracking processing
    public var isProcessingFrame: Bool = false
    
    // Array-based accumulation for noise reduction
    public var recentMatchIDs: [String] = []
    
    public init(scannedResult: OCRCardScannedResult?) {
      self.scannedResult = scannedResult
    }
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
    case imageDownloadCompleted(Card)
    case triggerMorph(Card)
    case morphAnimationFinished
    case resetScan
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
    Reduce(coreReduce)._printChanges(.actionLabels)
  }
  
  private func coreReduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .binding:
      return .none
      
    case let .trackingCornersUpdated(corners):
      state.latestTrackedCorners = corners
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
      guard !state.isScanningPaused else { return .none } // 🚀 Lock out new scans if we found our match
      guard state.dataSource == nil else { return .none }
      guard !state.isProcessingFrame else { return .none }
      state.isProcessingFrame = true
      
      return .run { send in
        let bestMatches = await imageHashManager.findBestMatches(for: result.value)
          .map { (id: $0.id, distance: $0.distance) }
        await send(.internalMatchesFound(bestMatches))
      }
      
    case let .internalMatchesFound(matches):
      state.isProcessingFrame = false
      
      guard !state.isScanningPaused else { return .none } // 🚀 Double check lock
      
      guard let topMatch = matches.first else {
        if state.dataSource == nil { state.status = .scanning }
        state.recentMatchIDs.removeAll()
        return .none
      }
      
      if state.recentMatchIDs.last == topMatch.id || state.recentMatchIDs.isEmpty {
        state.recentMatchIDs.append(topMatch.id)
      } else {
        state.recentMatchIDs = [topMatch.id]
      }
      
      guard state.recentMatchIDs.count >= 3 else {
        return .none
      }
      
      if state.dataSource == nil { state.status = .scanFound }
      
      state.isScanningPaused = true
      
      return .run { send in
        let card = try await client.queryCard(for: topMatch.id)
        await send(.singleCardFound(card))
      } catch: { error, send in
        print("Scryfall query failed: \(error)")
        await send(.resetScan)
      }.cancellable(id: CancelID.networkQuery, cancelInFlight: true)
      
    case let .singleCardFound(card):
      let setName = card.setName
      let subtitle = "\(setName) • #\(card.collectorNumber)"
      
      state.status = .cardDetails(title: card.name, subtitle: subtitle)
      state.dataSource = CardDataSource(cards: [card], hasNextPage: false, total: 1)
      
      return .run { send in
        if let urlString = card.imageUris?.normal, let url = URL(string: urlString) {
          do {
            var processors: [any ImageProcessing] = []
            if card.isLandscape {
              processors.append(RotationImageProcessor(degrees: 90))
            }
            
            let request = ImageRequest(url: url, processors: processors)
            let _ = try await ImagePipeline.shared.image(for: request)
            
            await send(.imageDownloadCompleted(card))
          } catch {
            await send(.triggerMorph(card))
          }
        } else {
          await send(.triggerMorph(card))
        }
      }.cancellable(id: CancelID.imageDownload, cancelInFlight: true)
      
    case let .imageDownloadCompleted(card):
      return .run { send in
        try await Task.sleep(nanoseconds: 150_000_000)
        await send(.triggerMorph(card))
      }.cancellable(id: CancelID.delayedMorph, cancelInFlight: true)
      
    case let .triggerMorph(_):
      state.isMorphed = true
      return .none
      
    case .morphAnimationFinished:
      state.isMorphAnimationComplete = true
      
      guard let card = state.dataSource?.cardDetails.first?.card else { return .none }
      return .run { send in
        await send(.fetchVariants(card))
      }.cancellable(id: CancelID.variantsQuery, cancelInFlight: true)
      
    case let .fetchVariants(card):
      let query = SearchQuery(oracleID: card.oracleId, page: 1, sortMode: .released, sortDirection: .auto)
      return .run { send in
        let data = try await client.queryCards(
          query
        ).data
        await send(.variantsLoaded(data), animation: .default)
      } catch: { error, send in
        print("Variants query failed: \(error)")
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
