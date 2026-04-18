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
    public var isScanningPaused: Bool = false
    
    public var lastQueriedMatchID: String? = nil
    public var lastTopMatchDistance: Float = 1.0
    public var isProcessingFrame: Bool = false
    
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
      // ✨ FIX: Always update the corners so the SwiftUI overlay continues to follow the real-world card.
      // (Removed the if state.isScanningPaused lock so it tracks while querying data)
      state.latestTrackedCorners = corners
      return .none
      
    case .resetScan:
      state.isMorphed = false
      state.dataSource = nil
      state.lastQueriedMatchID = nil
      state.isProcessingFrame = false
      state.status = .scanning
      
      // Reset the scanning and overlay UI
      state.isScanningPaused = false
      state.latestTrackedCorners = nil
      
      // 2. CANCEL EVERYTHING: Ensure no delayed tasks fire after closing
      return .merge(
        .cancel(id: CancelID.networkQuery),
        .cancel(id: CancelID.imageDownload),
        .cancel(id: CancelID.variantsQuery),
        .cancel(id: CancelID.delayedMorph)
      )
      
    case let .didScan(result):
      guard state.dataSource == nil else { return .none }
      guard !state.isProcessingFrame else { return .none }
      state.isProcessingFrame = true
      
      return .run(priority: .background) { send in
        let bestMatches = await imageHashManager.findBestMatches(for: result.value)
          .map { (id: $0.id, distance: $0.distance) }
        await send(.internalMatchesFound(bestMatches))
      }
      
    case let .internalMatchesFound(matches):
      state.isProcessingFrame = false
      
      guard let topMatch = matches.first else {
        if state.dataSource == nil { state.status = .scanning }
        return .none
      }
      
      // If we've already started querying a match, ignore straggler camera frames
      guard state.lastQueriedMatchID == nil else { return .none }
      
      if state.dataSource == nil { state.status = .scanFound }
      
      // Instantly confirm the very first match
      state.lastQueriedMatchID = topMatch.id
      state.lastTopMatchDistance = topMatch.distance
      
      // 3. STOP OCR IMMEDIATELY & CLEAR BOUNDS (Camera keeps running)
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
      
      // Populate data source with ONLY the initial card
      state.status = .cardDetails(title: card.name, subtitle: subtitle)
      state.dataSource = CardDataSource(cards: [card], hasNextPage: false, total: 1)
      
      // 4. Download Image, to overlay and morph
      return .run { send in
        if let urlString = card.imageUris?.normal, let url = URL(string: urlString) {
          do {
            // ✨ THE FIX: Match the exact processors used in CardRemoteImageView
            var processors: [any ImageProcessing] = []
            if card.isLandscape {
              processors.append(RotationImageProcessor(degrees: 90))
            }
            
            // Fetch using the explicit request so the processed image enters the memory cache
            let request = ImageRequest(url: url, processors: processors)
            let _ = try await ImagePipeline.shared.image(for: request)
            
            await send(.imageDownloadCompleted(card))
          } catch {
            print("Image download failed: \(error)")
            await send(.triggerMorph(card))
          }
        } else {
          await send(.triggerMorph(card))
        }
      }.cancellable(id: CancelID.imageDownload, cancelInFlight: true)
      
    case let .imageDownloadCompleted(card):
      // 5. MORPH CANCELLATION: Small delay ensuring SwiftUI mounts overlay before morphing
      return .run { send in
        try await Task.sleep(nanoseconds: 50_000_000)
        await send(.triggerMorph(card))
      }.cancellable(id: CancelID.delayedMorph, cancelInFlight: true)
      
    case let .triggerMorph(card):
      state.isMorphed = true
      
      // 6. CHAINED VARIANTS: Fetch variants seamlessly after the UI morph begins
      return .run { send in
        // Wait briefly (0.5s) to let the 3D zoom animation finish before parsing JSON
        try await Task.sleep(nanoseconds: 500_000_000)
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
