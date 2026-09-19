import Foundation
import UIKit
import ComposableArchitecture
import Nuke
import ScryfallKit
import Networking
import DesignComponents

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
    public var pendingVariants: [Card]? = nil
    public var latestTrackedCorners: QuadCorners? = nil
    public var isMorphed: Bool = false
    public var transientImage: PlatformImage?
    public var isMorphAnimationComplete: Bool = false
    public var isScanningPaused: Bool = false
    public var isProcessingFrame: Bool = false
    public var recentMatchIDs: [String] = []
    public var viewSize: CGSize? = nil
    public var topSafeArea: CGFloat = 0
    public var bottomSafeArea: CGFloat = 0
    
    public init() {}
  }
  
  public enum Action: Sendable, BindableAction {
    case binding(BindingAction<State>)
    case trackingCornersUpdated(QuadCorners?)
    case didScan(ScannedImage)
    case internalMatchesFound([MatchResult])
    case singleCardFound(Card, face: MagicCardFaceDirection)
    case variantsLoaded([Card])
    case mergePendingVariants
    case syncCardImageHashDatabase
    case syncCompleted
    case updateMorphAnimation(isCompleted: Bool)
    case imageDownloaded(PlatformImage)
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
      
    case .binding:
      return .none
      
    case let .updateSafeAreas(top, bottom):
      state.topSafeArea = top
      state.bottomSafeArea = bottom
      return .none
      
    case let .trackingCornersUpdated(corners):
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
      state.pendingVariants = nil
      state.isProcessingFrame = false
      state.status = .scanning
      state.isScanningPaused = false
      state.latestTrackedCorners = nil
      state.recentMatchIDs.removeAll()
      state.transientImage = nil
      
      return .merge(
        .cancel(id: CancelID.networkQuery),
        .cancel(id: CancelID.imageDownload),
        .cancel(id: CancelID.variantsQuery),
        .cancel(id: CancelID.delayedMorph)
      )
      
    case let .updateMorphAnimation(isCompleted):
      state.isMorphAnimationComplete = isCompleted
      return .none
      
    case let .didScan(result):
      guard !state.isScanningPaused, state.dataSource == nil, !state.isProcessingFrame else { return .none }
      state.isProcessingFrame = true
      let img = result.value
      
      return .run { send in
        await send(.internalMatchesFound(await imageHashManager.findBestMatches(for: img)))
      }
      
    case let .internalMatchesFound(matches):
      state.isProcessingFrame = false
      guard !state.isScanningPaused else { return .none }
      
      guard let topMatch = matches.first else {
        if state.dataSource == nil { state.status = .scanning }
        state.recentMatchIDs.removeAll()
        return .none
      }
      
      // Frames agree on the card, not the face: two similar faces of one card
      // alternating between frames still settle, on the face seen last.
      if state.recentMatchIDs.last == topMatch.cardID {
        if state.recentMatchIDs.count < ScannerConstants.maxRecentMatchIDs {
          state.recentMatchIDs.append(topMatch.cardID)
        }
      } else {
        state.recentMatchIDs = [topMatch.cardID]
      }
      
      guard state.recentMatchIDs.count >= ScannerConstants.requiredMatchFrames else { return .none }
      
      if state.dataSource == nil { state.status = .scanFound }
      state.isScanningPaused = true
      
      let face: MagicCardFaceDirection = (topMatch.faceIndex ?? 0) > 0 ? .back : .front
      return .run { send in
        let card = try await client.queryCard(for: topMatch.cardID)
        await send(.singleCardFound(card, face: face))
      } catch: { _, send in
        await send(.resetScan)
      }.cancellable(id: CancelID.networkQuery, cancelInFlight: true)
      
    case let .singleCardFound(card, face):
      // Only a card whose faces have their own images can have its back scanned.
      let showsBack = face == .back && (card.cardFaces?.count ?? 0) > 1
      let title = card.isTransformable ? card.name(faceDirection: showsBack ? .back : .front) : card.name
      state.status = .cardDetails(title: title, subtitle: "\(card.setName) • #\(card.collectorNumber)")
      var dataSource = CardDataSource(cards: [card], hasNextPage: false, total: 1)
      if showsBack {
        dataSource.cardDetails[0].displayableCardImage = dataSource.cardDetails[0].displayableCardImage?.toggled()
      }
      state.dataSource = dataSource
      
      let imageEffect: Effect<Action> = .run { send in
        if let url = card.getImageURL(type: .normal, getSecondFace: showsBack) {
          var processors: [any ImageProcessing] = []
          if card.isLandscape {
            processors.append(RotationImageProcessor(degrees: 90))
          }
          let request = ImageRequest(url: url, processors: processors)
          if let image = try? await ImagePipeline.shared.image(for: request) {
            await send(.imageDownloaded(image))
          }
        }
      }.cancellable(id: CancelID.imageDownload, cancelInFlight: true)
      
      let variantsEffect: Effect<Action> = .run { send in
        let query = SearchQuery(
          // Reversible cards keep their oracle id on each face.
          oracleID: card.oracleId ?? card.getCardFace(for: showsBack ? .back : .front)?.oracleId,
          page: 1,
          sortMode: .released,
          sortDirection: .auto
        )
        
        let data = try await client.queryCards(query).data
        await send(.variantsLoaded(data))
      } catch: { _, _ in
      }.cancellable(id: CancelID.variantsQuery, cancelInFlight: true)
      
      return .merge(imageEffect, variantsEffect)
      
    case let .imageDownloaded(image):
      state.transientImage = image
      return .none
      
    case .triggerMorph:
      state.isMorphed = true
      return .none
      
    case .morphAnimationFinished:
      return .run { send in
        await send(.updateMorphAnimation(isCompleted: true))
        await send(.mergePendingVariants, animation: .default)
      }
      
    case let .variantsLoaded(variants):
      state.pendingVariants = variants
      return .run { send in
        await send(.mergePendingVariants, animation: .default)
      }
      
    case .mergePendingVariants:
      guard
        state.isMorphAnimationComplete,
        let variants = state.pendingVariants,
        let scanned = state.dataSource?.cardDetails.first
      else {
        return .none
      }
      
      // The scanned card is kept as shown rather than rebuilt, which would turn
      // it back to its front, and its printings are turned to the same face.
      var dataSource = CardDataSource(
        cards: variants.filter { $0.id != scanned.card.id },
        hasNextPage: false,
        total: 0
      )
      if scanned.displayableCardImage?.faceDirection == .back {
        for index in dataSource.cardDetails.indices where dataSource.cardDetails[index].card.isTransformable {
          dataSource.cardDetails[index].displayableCardImage = dataSource.cardDetails[index].displayableCardImage?.toggled()
        }
      }
      dataSource.cardDetails.insert(scanned, at: 0)
      dataSource.total = dataSource.cardDetails.count
      
      state.dataSource = dataSource
      state.pendingVariants = nil
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
