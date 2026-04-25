import SwiftUI
import DesignComponents
import Nuke
import ScryfallKit
import ComposableArchitecture
import VariableBlur
import Foundation
import Networking

public struct RootView: View {
  @Bindable var store: StoreOf<CardScannerFeature>
  
  private var hasScannedCard: Bool {
    store.dataSource != nil
  }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
  
  public var body: some View {
    NavigationView {
      ZStack(alignment: .bottom) {
        ZStack(alignment: .center) {
          cameraLayer
          floatingMorphLayer
          
          if let viewSize = store.viewSize {
            let containerWidth = viewSize.width - 110
            let cardHeight = containerWidth / (63.0 / 88.0)
            let topOffset = (viewSize.height / 2) - 40 - (cardHeight / 2)
            
            VStack(spacing: 0) {
              Spacer(minLength: topOffset)
              scrollableCardsLayer
              Spacer(minLength: 0)
            }
          }
        }
        
        bottomToolBarLayer
      }
      .onGeometryChange(for: CGSize.self, of: { proxy in proxy.size }, action: { newValue in
        store.send(.updateViewSize(newValue))
      })
      .toolbar { navigationToolbar }
      .ignoresSafeArea(.all)
      .task { store.send(.syncCardImageHashDatabase) }
      .onAppear {
        if
          let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first {
          store.send(.updateSafeAreas(
            top: window.safeAreaInsets.top,
            bottom: window.safeAreaInsets.bottom
          ))
        }
      }
    }
    .colorScheme(.dark)
  }
  
  @ViewBuilder
  private var cameraLayer: some View {
    OCRView(
      isScanningPaused: store.isScanningPaused,
      isProcessingFrame: store.isProcessingFrame,
      isTrackingPaused: store.isMorphed,
      onValidatedScan: { result in store.send(.didScan(result)) },
      onTrackingUpdate: { corners in store.send(.trackingCornersUpdated(corners)) }
    )
    .background(.black)
  }
  
  @ViewBuilder
  private var floatingMorphLayer: some View {
    if !store.isMorphAnimationComplete {
      let targetCorners: QuadCorners? = {
        if store.isMorphed, let viewSize = store.viewSize {
          return uprightCorners(fallbackSize: viewSize)
        } else if let baseCorners = store.latestTrackedCorners {
          return adjustedCorners(for: baseCorners, orientation: store.matchedOrientation)
        } else {
          return nil
        }
      }()
      
      if let cornersToDraw = targetCorners, let cardInfo = store.dataSource?.cardDetails.first, let viewSize = store.viewSize {
        let containerWidth = viewSize.width - 110
        let configuration = CardView.LayoutConfiguration(
          rotation: cardInfo.card.isLandscape ? .landscape : .portrait,
          maxWidth: containerWidth.rounded()
        )
        
        CardView(displayableCard: cardInfo.displayableCardImage, priceVisibility: .hidden)
          .projected(to: cornersToDraw, size: configuration.size)
          .ignoresSafeArea()
          .animation(store.isMorphed ? .bouncy(duration: 0.6) : .easeOut(duration: 0.315), value: cornersToDraw)
      }
    }
  }
  
  @ViewBuilder
  private var scrollableCardsLayer: some View {
    if let viewSize = store.viewSize {
      let containerWidth = viewSize.width - 110
      
      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 8) {
          if let cardDetails = store.dataSource?.cardDetails {
            ForEach(Array(cardDetails.enumerated()), id: \.element.id) { index, cardInfo in
              scrollableCardItem(index: index, cardInfo: cardInfo, containerWidth: containerWidth)
            }
          }
        }
        .padding(.horizontal, 55)
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollIndicators(.hidden)
      .opacity(hasScannedCard ? 1.0 : 0.0)
    }
  }
  
  @ViewBuilder
  private func scrollableCardItem(index: Int, cardInfo: CardInfo, containerWidth: CGFloat) -> some View {
    let isFirst = index == 0
    let showImage = !(isFirst && !store.isMorphAnimationComplete)
    let showDetails = store.isMorphed
    
    let configuration = CardView.LayoutConfiguration(
      rotation: .portrait,
      maxWidth: containerWidth.rounded()
    )
    
    VStack(spacing: 13.0) {
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
          HStack(alignment: .center, spacing: 3) {
            Text(cardInfo.formattedSetCode).fontWidth(.condensed)
          }
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
            PillText(usdFoilPrice, isFoil: true).foregroundStyle(.black.opacity(0.8)).padding(.all, 2)
          }
          if let usdEtched = cardInfo.displayPriceUSDEtched {
            PillText(usdEtched, isFoil: true).foregroundStyle(.black.opacity(0.8)).padding(.all, 2)
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
  
  @ViewBuilder
  private var bottomToolBarLayer: some View {
    GlassEffectContainer {
      HStack(spacing: 34.0) {
        Spacer()
        if hasScannedCard {
          Button(action: {}) { Image(systemName: "square.grid.2x2.fill").font(.body).frame(width: 55, height: 55) }
            .glassEffect(.clear.interactive())
        }
        
        if hasScannedCard {
          Button(action: {}) { Image(systemName: "plus").font(.title) }
            .frame(width: 89, height: 89)
            .glassEffect(.clear.interactive())
        } else {
          Button(action: {}) { Circle().fill(.white).frame(width: 77, height: 77) }
            .frame(width: 89, height: 89)
            .glassEffect(.clear.interactive())
        }
        
        if hasScannedCard {
          Button(action: {}) { Image(systemName: "info").font(.body).frame(width: 55, height: 55) }
            .glassEffect(.clear.interactive())
        }
        Spacer()
      }
      .fontWeight(.semibold)
    }
    .padding(.bottom, store.bottomSafeArea + 80)
    .animation(.bouncy(duration: 0.5, extraBounce: 0.1), value: hasScannedCard)
  }
  
  @ToolbarContentBuilder
  private var navigationToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button(action: { print("Bug button tapped") }) { Image(systemName: "ladybug.fill") }
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
  
  private func uprightCorners(fallbackSize: CGSize) -> QuadCorners {
    let cardWidth = fallbackSize.width - 110
    let cardHeight = cardWidth / (63.0 / 88.0)
    let midX = fallbackSize.width / 2
    let midY = (fallbackSize.height / 2) - 40
    
    let halfW = cardWidth / 2
    let halfH = cardHeight / 2
    return QuadCorners(
      topLeft: CGPoint(x: midX - halfW, y: midY - halfH),
      topRight: CGPoint(x: midX + halfW, y: midY - halfH),
      bottomRight: CGPoint(x: midX + halfW, y: midY + halfH),
      bottomLeft: CGPoint(x: midX - halfW, y: midY + halfH)
    )
  }
  
  private func adjustedCorners(for corners: QuadCorners, orientation: PhysicalOrientation) -> QuadCorners {
    switch orientation {
    case .upright:
      return corners
    case .tappedRight:
      return QuadCorners(topLeft: corners.topRight, topRight: corners.bottomRight, bottomRight: corners.bottomLeft, bottomLeft: corners.topLeft)
    case .upsideDown:
      return QuadCorners(topLeft: corners.bottomRight, topRight: corners.bottomLeft, bottomRight: corners.topLeft, bottomLeft: corners.topRight)
    case .tappedLeft:
      return QuadCorners(topLeft: corners.bottomLeft, topRight: corners.topLeft, bottomRight: corners.topRight, bottomLeft: corners.bottomRight)
    }
  }
}
