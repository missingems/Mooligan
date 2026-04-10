import ComposableArchitecture
import ScryfallKit
import DesignComponents
import Networking
import Foundation
import Nuke
import UIKit

private let kMinConfidenceDistance: Float = 0.35
private let kSameCardDistanceTolerance: Float = 0.08
private let kRequiredConfirmationCount: Int = 3

public struct SendableImage: @unchecked Sendable, Equatable {
  public let uiImage: UIImage
  public init(_ uiImage: UIImage) { self.uiImage = uiImage }
}

@Reducer public struct CardScannerFeature: Sendable {
  @Dependency(\.cardQueryRequestClient) var client
  @Dependency(\.cardImageHashSyncManager) var imageHashManager
  
  private enum CancelID {
    case networkQuery
    case imageDownload
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
        
      case let .trackingCornersUpdated(corners):
        state.latestTrackedCorners = corners
        return .none
        
      case .resetScan:
        state.scrolledCardID = nil
        state.isMorphed = false
        state.dataSource = nil
        state.downloadedCardImage = nil
        // Cancel any in-flight downloads or queries when resetting
        return .merge(
          .cancel(id: CancelID.networkQuery),
          .cancel(id: CancelID.imageDownload)
        )
        
        // 1. Scan for card
      case let .didScan(result):
        guard !state.isProcessingFrame else { return .none }
        state.isProcessingFrame = true
        
        return .run { send in
          let bestMatches = await imageHashManager.findBestMatches(for: result.value)
            .map { (id: $0.id, distance: $0.distance) }
          await send(.internalMatchesFound(bestMatches))
        }
        
        // 2. Found Card -> Verify internal matches
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
        
        // 3. Download card here using Nuke ImagePipeline
        if let card = state.scrolledCard,
           let urlString = card.card.imageUris?.large,
           let url = URL(string: urlString) {
          return .run { send in
            do {
              let response = try await ImagePipeline.shared.image(for: url)
              
              // 4. Trigger action update with animation once downloaded
              await send(
                .imageDownloadCompleted(SendableImage(response))
              )
            } catch {
              print("Image download failed: \(error)")
            }
          }
          .cancellable(id: CancelID.imageDownload, cancelInFlight: true)
        }
        return .none
        
        // 4. Action updates the border position and saves the image
      case let .imageDownloadCompleted(image):
        state.downloadedCardImage = image
        state.isMorphed = true
        return .none
        
      case .syncCardImageHashDatabase:
        return .run { send in
          await imageHashManager.sync()
        }
      }
    }
  }
  
  public init() {}
}

public extension CardScannerFeature {
  @ObservableState struct State: Sendable, Equatable {
    var scannedResult: OCRCardScannedResult?
    var dataSource: CardDataSource?
    var queryWithSetCode: SearchQuery?
    var queryWithoutSetCode: SearchQuery?
    
    var latestTrackedCorners: QuadCorners? = nil
    var scrolledCardID: UUID?
    var downloadedCardImage: SendableImage? = nil
    var isMorphed: Bool = false
    
    var scrolledCard: CardInfo? {
      guard let id = scrolledCardID, let details = dataSource?.cardDetails else { return nil }
      return details.first(where: { $0.card.id == id })
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
    case trackingCornersUpdated(QuadCorners?)
    case didScan(ScannedImage)
    case internalMatchesFound([(id: String, distance: Float)])
    case updateMatches(CardDataSource)
    case syncCardImageHashDatabase
    case imageDownloadCompleted(SendableImage)
    case resetScan
  }
  
  enum SyncStatus: Equatable, Sendable {
    case syncing
    case checkingForUpdates
    case synced
    case syncedFailure
  }
}
