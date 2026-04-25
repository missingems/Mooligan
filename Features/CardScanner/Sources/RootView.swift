import SwiftUI
import DesignComponents
import Nuke
import ScryfallKit
import ComposableArchitecture
import VariableBlur
import Foundation
import Networking

// MARK: - Layout Constants

private enum Layout {
  static let cardHorizontalMargin: CGFloat    = 110
  static let cardHorizontalPadding: CGFloat   = 55
  static let cardAspectRatio: CGFloat         = 63.0 / 88.0
  static let verticalCenterAdjustment: CGFloat = 40
  static let cardItemSpacing: CGFloat         = 8
  static let cardDetailSpacing: CGFloat       = 13
  static let toolbarExtraBottomPadding: CGFloat = 80
  static let toolbarButtonSpacing: CGFloat    = 34
  static let primaryButtonSize: CGFloat       = 89
  static let secondaryButtonSize: CGFloat     = 55
  static let captureButtonInnerSize: CGFloat  = 77
}

private struct CardLayoutMetrics {
  let containerWidth: CGFloat
  let cardHeight: CGFloat
  let topOffset: CGFloat
  
  init(viewSize: CGSize) {
    containerWidth = viewSize.width - Layout.cardHorizontalMargin
    cardHeight = containerWidth / Layout.cardAspectRatio
    topOffset = (viewSize.height / 2) - Layout.verticalCenterAdjustment - (cardHeight / 2)
  }
}

public struct RootView: View {
  @Bindable var store: StoreOf<CardScannerFeature>
  
  private var hasScannedCard: Bool { store.dataSource != nil }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
  
  public var body: some View {
    NavigationStack {
      ZStack(alignment: .bottom) {
        ZStack(alignment: .center) {
          cameraLayer
          floatingMorphLayer
          
          if let viewSize = store.viewSize {
            let metrics = CardLayoutMetrics(viewSize: viewSize)
            VStack(spacing: 0) {
              Spacer(minLength: metrics.topOffset)
              scrollableCardsLayer(metrics: metrics)
              Spacer(minLength: 0)
            }
          }
        }
        
        bottomToolBarLayer
      }
      .onGeometryChange(for: CGSize.self, of: { $0.size }) { size in
        store.send(.updateViewSize(size))
      }
      .onGeometryChange(for: EdgeInsets.self, of: { $0.safeAreaInsets }) { insets in
        store.send(.updateSafeAreas(top: insets.top, bottom: insets.bottom))
      }
      .toolbar { navigationToolbar }
      .ignoresSafeArea(.all)
      .task { store.send(.syncCardImageHashDatabase) }
    }
    .colorScheme(.dark)
  }
  
  // MARK: - Camera
  
  @ViewBuilder
  private var cameraLayer: some View {
    OCRView(
      isScanningPaused: store.isScanningPaused,
      isProcessingFrame: store.isProcessingFrame,
      isTrackingPaused: store.isMorphed,
      onValidatedScan: { store.send(.didScan($0)) },
      onTrackingUpdate: { store.send(.trackingCornersUpdated($0)) }
    )
    .background(.black)
  }
  
  // MARK: - Floating Morph Layer
  
  @ViewBuilder
  private var floatingMorphLayer: some View {
    if !store.isMorphAnimationComplete,
       let viewSize = store.viewSize,
       let cardInfo = store.dataSource?.cardDetails.first {
      
      // When morphed, animate to the computed upright position.
      // Before morphing, show the card projected at the live tracked corners.
      // If corners haven't been set yet, nothing is shown — avoids a
      // premature "pop" to the upright position before tracking locks in.
      let targetCorners: QuadCorners? = store.isMorphed
      ? uprightCorners(for: viewSize)
      : store.latestTrackedCorners
      
      if let cornersToDraw = targetCorners {
        let containerWidth = viewSize.width - Layout.cardHorizontalMargin
        let configuration = CardView.LayoutConfiguration(
          rotation: cardInfo.card.isLandscape ? .landscape : .portrait,
          maxWidth: containerWidth.rounded()
        )
        
        CardView(displayableCard: cardInfo.displayableCardImage, priceVisibility: .hidden)
          .projected(to: cornersToDraw, size: configuration.size)
          .ignoresSafeArea()
          .animation(
            store.isMorphed ? .bouncy(duration: 0.6) : .easeOut(duration: 0.315),
            value: cornersToDraw
          )
      }
    }
  }
  
  // MARK: - Scrollable Cards
  
  @ViewBuilder
  private func scrollableCardsLayer(metrics: CardLayoutMetrics) -> some View {
    ScrollView(.horizontal) {
      LazyHStack(alignment: .top, spacing: Layout.cardItemSpacing) {
        if let cardDetails = store.dataSource?.cardDetails {
          // FIX: was ForEach(Array(cardDetails.enumerated()), id: \.element.id) which
          // allocates a new heap array on every render pass. ForEach over the
          // collection directly with card identity avoids that allocation, and
          // isFirst is derived by comparing against the first element's id.
          ForEach(cardDetails, id: \.id) { cardInfo in
            let isFirst = cardInfo.id == cardDetails.first?.id
            scrollableCardItem(
              isFirst: isFirst,
              cardInfo: cardInfo,
              containerWidth: metrics.containerWidth
            )
          }
        }
      }
      .padding(.horizontal, Layout.cardHorizontalPadding)
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
    .opacity(hasScannedCard ? 1.0 : 0.0)
  }
  
  @ViewBuilder
  private func scrollableCardItem(
    isFirst: Bool,
    cardInfo: CardInfo,
    containerWidth: CGFloat
  ) -> some View {
    let showImage   = !(isFirst && !store.isMorphAnimationComplete)
    let showDetails = store.isMorphed
    
    let configuration = CardView.LayoutConfiguration(
      rotation: .portrait,
      maxWidth: containerWidth.rounded()
    )
    
    VStack(spacing: Layout.cardDetailSpacing) {
      CardView(
        displayableCard: cardInfo.displayableCardImage,
        layoutConfiguration: configuration,
        priceVisibility: .hidden,
        shouldShowShadow: false
      )
      .frame(width: configuration.size.width, height: configuration.size.height)
      .opacity(showImage ? 1.0 : 0.0)
      
      VStack(alignment: .center, spacing: 5.0) {
        Text(cardInfo.formattedSetName)
          .font(.headline)
          .multilineTextAlignment(.center)
          .lineLimit(2)
        
        HStack(spacing: 8.0) {
          Text(cardInfo.formattedSetCode).fontWidth(.condensed)
          Text(cardInfo.formattedCollectorNumber).fontDesign(.serif)
        }
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .font(.caption)
        .fontWeight(.medium)
        
        HStack(spacing: 5) {
          if let usdPrice = cardInfo.displayPriceUSD {
            PillText(usdPrice).padding(.all, 2)
          }
          if let usdFoilPrice = cardInfo.displayPriceUSDFoil {
            PillText(usdFoilPrice, isFoil: true)
              .foregroundStyle(.black.opacity(0.8))
              .padding(.all, 2)
          }
          if let usdEtched = cardInfo.displayPriceUSDEtched {
            PillText(usdEtched, isFoil: true)
              .foregroundStyle(.black.opacity(0.8))
              .padding(.all, 2)
          }
        }
        .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
        .font(.caption)
        .fontWeight(.medium)
        .monospaced()
        .fixedSize(horizontal: true, vertical: true)
      }
      .opacity(showDetails ? 1.0 : 0.0)
      .frame(width: containerWidth)
    }
  }
  
  // MARK: - Bottom Toolbar
  
  @ViewBuilder
  private var bottomToolBarLayer: some View {
    GlassEffectContainer {
      HStack(spacing: Layout.toolbarButtonSpacing) {
        Spacer()
        if hasScannedCard {
          Button(action: {}) {
            Image(systemName: "square.grid.2x2.fill")
              .font(.body)
              .frame(width: Layout.secondaryButtonSize, height: Layout.secondaryButtonSize)
          }
          .glassEffect(.clear.interactive())
        }
        
        if hasScannedCard {
          Button(action: {}) {
            Image(systemName: "plus").font(.title)
          }
          .frame(width: Layout.primaryButtonSize, height: Layout.primaryButtonSize)
          .glassEffect(.clear.interactive())
        } else {
          Button(action: {}) {
            Circle()
              .fill(.white)
              .frame(width: Layout.captureButtonInnerSize, height: Layout.captureButtonInnerSize)
          }
          .frame(width: Layout.primaryButtonSize, height: Layout.primaryButtonSize)
          .glassEffect(.clear.interactive())
        }
        
        if hasScannedCard {
          Button(action: {}) {
            Image(systemName: "info")
              .font(.body)
              .frame(width: Layout.secondaryButtonSize, height: Layout.secondaryButtonSize)
          }
          .glassEffect(.clear.interactive())
        }
        Spacer()
      }
      .fontWeight(.semibold)
    }
    .padding(.bottom, store.bottomSafeArea + Layout.toolbarExtraBottomPadding)
    .animation(.bouncy(duration: 0.5, extraBounce: 0.1), value: hasScannedCard)
  }
  
  // MARK: - Navigation Toolbar
  
  @ToolbarContentBuilder
  private var navigationToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button(action: { print("Bug button tapped") }) {
        Image(systemName: "ladybug.fill")
      }
    }
    ToolbarItem(id: "info", placement: .principal) {
      Text(store.status.displayTitle).font(.headline)
    }
    ToolbarItem(placement: .topBarTrailing) {
      if hasScannedCard {
        Button(role: .close) { store.send(.resetScan) }
      }
    }
  }
  
  // MARK: - Helpers
  
  private func uprightCorners(for viewSize: CGSize) -> QuadCorners {
    let cardWidth = viewSize.width - Layout.cardHorizontalMargin
    let cardHeight = cardWidth / Layout.cardAspectRatio
    let midX  = viewSize.width / 2
    let midY  = (viewSize.height / 2) - Layout.verticalCenterAdjustment
    let halfW = cardWidth / 2
    let halfH = cardHeight / 2
    return QuadCorners(
      topLeft:     CGPoint(x: midX - halfW, y: midY - halfH),
      topRight:    CGPoint(x: midX + halfW, y: midY - halfH),
      bottomRight: CGPoint(x: midX + halfW, y: midY + halfH),
      bottomLeft:  CGPoint(x: midX - halfW, y: midY + halfH)
    )
  }
}
