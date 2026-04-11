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
  @Dependency(\.cardQueryRequestClient) var client
  @Dependency(\.cardImageHashSyncManager) var imageHashManager
  
  private enum CancelID {
    case networkQuery
    case imageDownload
    case variantsQuery
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
        state.lastQueriedMatchID = nil
        state.pendingMatchID = nil
        state.pendingMatchCount = 0
        state.isProcessingFrame = false
        state.status = .scanning
        
        return .merge(
          .cancel(id: CancelID.networkQuery),
          .cancel(id: CancelID.imageDownload),
          .cancel(id: CancelID.variantsQuery)
        )
        
        // 1. Scan for card
      case let .didScan(result):
        guard state.dataSource == nil else { return .none }
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
          if state.dataSource == nil { state.status = .scanning }
          return .none
        }
        
        if state.dataSource == nil { state.status = .scanFound }
        
        if state.lastQueriedMatchID == topMatch.id {
          state.pendingMatchCount += 1
          return .none
        }
        if let lastQueriedID = state.lastQueriedMatchID, matches.prefix(3).contains(where: { $0.id == lastQueriedID }) {
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
        guard state.pendingMatchCount >= kRequiredConfirmationCount else { return .none }
        
        state.lastQueriedMatchID = topMatch.id
        state.lastTopMatchDistance = topMatch.distance
        state.pendingMatchID = nil
        state.pendingMatchCount = 0
        
        if let value = matches.first?.id {
          return .run { send in
            let card = try await client.queryCard(for: value)
            await send(.singleCardFound(card))
          } catch: { error, send in
            print("Scryfall query failed: \(error)")
            await send(.resetScan)
          }.cancellable(id: CancelID.networkQuery, cancelInFlight: true)
        } else {
          return .none
        }
        
        // 3. Handle the single initial card
      case let .singleCardFound(card):
        let setName = card.setName ?? card.set.uppercased()
        let subtitle = "\(setName) • #\(card.collectorNumber)"
        
        state.status = .cardDetails(title: card.name, subtitle: subtitle)
        state.dataSource = CardDataSource(cards: [card], hasNextPage: false, total: 1)
        state.scrolledCardID = card.id
        
        let fetchVariantsEffect: Effect<Action> = .run { send in
          try await Task.sleep(nanoseconds: 20_000_000_0)
          await send(.fetchVariants(card.name))
        }
        
        if let urlString = card.imageUris?.large, let url = URL(string: urlString) {
          let downloadImageEffect: Effect<Action> = .run { send in
            do {
              let response = try await ImagePipeline.shared.image(for: url)
              await send(.imageDownloadCompleted(SendableImage(response)))
            } catch {
              print("Image download failed: \(error)")
            }
          }.cancellable(id: CancelID.imageDownload, cancelInFlight: true)
          
          return .concatenate(downloadImageEffect, fetchVariantsEffect)
        } else {
          return .none
        }
        
      case let .fetchVariants(name):
        return .run { send in
          let data = try await client.queryCards(SearchQuery(name: name, page: 1, sortMode: .released, sortDirection: .auto)).data
          await send(.variantsLoaded(data))
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
        
      case let .imageDownloadCompleted(image):
        state.downloadedCardImage = image
        return .run { send in
          try await Task.sleep(nanoseconds: 100_000_000)
          await send(.triggerMorph)
        }
        
      case .triggerMorph:
        state.isMorphed = true
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
  }
  
  public init() {}
}

public extension CardScannerFeature {
  @ObservableState struct State: Sendable, Equatable {
    var status: ScannerStatus = .loading
    
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
    case singleCardFound(Card)
    case fetchVariants(String)
    case variantsLoaded([Card])
    case syncCardImageHashDatabase
    case syncCompleted
    case imageDownloadCompleted(SendableImage)
    case triggerMorph
    case resetScan
  }
  
  enum SyncStatus: Equatable, Sendable {
    case syncing
    case checkingForUpdates
    case synced
    case syncedFailure
  }
}
