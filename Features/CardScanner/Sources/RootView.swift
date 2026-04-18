import SwiftUI
import DesignComponents
import Nuke
import ScryfallKit
import ComposableArchitecture
import VariableBlur
import Foundation
import Networking

// MARK: - Preference Key for Pixel-Perfect Morphing
struct TargetCardFrameKey: @MainActor PreferenceKey {
  @MainActor static var defaultValue: CGRect = .zero
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    let next = nextValue()
    if next != .zero { value = next }
  }
}

public struct RootView: View {
  @Bindable var store: StoreOf<CardScannerFeature>
  @State private var bottomSafeArea: CGFloat = 0
  @State private var topSafeArea: CGFloat = 0
  @Namespace private var morphNamespace
  
  @State private var viewSize: CGSize = UIScreen.main.bounds.size
  
  @State private var lastValidCorners: QuadCorners? = nil
  @State private var morphAnimationComplete: Bool = false
  @State private var targetCardFrame: CGRect = .zero
  
  private var hasScannedCard: Bool {
    store.dataSource != nil
  }
  
  public var body: some View {
    NavigationView {
      ZStack(alignment: .bottom) {
        ZStack(alignment: .center) {
          cameraLayer
          floatingMorphLayer
          scrollableCardsLayer
        }
        .coordinateSpace(name: "RootSpace")
        .onPreferenceChange(TargetCardFrameKey.self) { frame in
          if frame != .zero { self.targetCardFrame = frame }
        }
        
        bottomToolBarLayer
      }
      .onGeometryChange(for: CGSize.self, of: { proxy in proxy.size }, action: { newValue in self.viewSize = newValue })
      .toolbar { navigationToolbar }
      .ignoresSafeArea(.all)
      .task { store.send(.syncCardImageHashDatabase) }
      .onAppear {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first {
          bottomSafeArea = window.safeAreaInsets.bottom
          topSafeArea = window.safeAreaInsets.top
        }
      }
    }
    .colorScheme(.dark)
  }
  
  @ViewBuilder
  private var cameraLayer: some View {
    OCRView(
      isScanningPaused: store.isScanningPaused,
      isTrackingPaused: store.isMorphed,
      onValidatedScan: { result in store.send(.didScan(result)) },
      onTrackingUpdate: { corners in store.send(.trackingCornersUpdated(corners)) }
    )
    .background(.black)
  }
  
  @ViewBuilder
  private var floatingMorphLayer: some View {
    Group {
      if !morphAnimationComplete {
        let targetCorners = store.isMorphed
        ? uprightCorners(from: targetCardFrame, fallbackSize: viewSize)
        : (store.latestTrackedCorners ?? lastValidCorners)
        
        if let cornersToDraw = targetCorners, let cardInfo = store.dataSource?.cardDetails.first {
          let isTracking = store.latestTrackedCorners != nil || store.isMorphed
          
          // ✨ DYNAMIC SIZE CALCULATION: Matches the ScrollView destination perfectly
          let containerWidth = viewSize.width - 110
          let configuration = CardView.LayoutConfiguration(
            rotation: cardInfo.card.isLandscape ? .landscape : .portrait,
            maxWidth: containerWidth.rounded()
          )
          
          CardView(displayableCard: cardInfo.displayableCardImage, priceVisibility: .hidden)
          // Use the dynamically calculated size from your LayoutConfiguration
            .projected(to: cornersToDraw, size: configuration.size)
            .ignoresSafeArea()
            .animation(store.isMorphed ? .bouncy : .easeOut(duration: 0.315), value: cornersToDraw)
            .opacity(isTracking ? 1.0 : 0.0)
            .animation(isTracking ? .easeOut(duration: 0.2) : .easeIn(duration: 0.35).delay(0.6), value: isTracking)
        }
      }
    }
    .onChange(of: store.latestTrackedCorners) { oldValue, newValue in
      if let newValue { lastValidCorners = newValue }
    }
    .onChange(of: store.isMorphed) { oldValue, newValue in
      if newValue {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
          if store.isMorphed { self.morphAnimationComplete = true }
        }
      } else {
        self.morphAnimationComplete = false
      }
    }
  }
  
  @ViewBuilder
  private var scrollableCardsLayer: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        if let cardDetails = store.dataSource?.cardDetails {
          let containerWidth = viewSize.width - 110
          
          ForEach(Array(cardDetails.enumerated()), id: \.element.card.id) { index, cardInfo in
            scrollableCardItem(index: index, cardInfo: cardInfo, containerWidth: containerWidth)
          }
        }
      }
      .padding(.horizontal, 55)
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
    .offset(y: -40)
    .opacity(hasScannedCard ? 1.0 : 0.0)
  }
  
  @ViewBuilder
  private func scrollableCardItem(index: Int, cardInfo: CardInfo, containerWidth: CGFloat) -> some View {
    let isFirst = index == 0
    let showImage = !(isFirst && !morphAnimationComplete)
    let showDetails = store.isMorphed
    
    let configuration = CardView.LayoutConfiguration(
      rotation: cardInfo.card.isLandscape ? .landscape : .portrait,
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
      .background(
        GeometryReader { geo in
          Color.clear.preference(
            key: TargetCardFrameKey.self,
            value: isFirst ? geo.frame(in: .named("RootSpace")) : .zero
          )
        }
      )
      .opacity(showImage ? 1.0 : 0.0)
      
      VStack(alignment: .center, spacing: 5.0) {
        Text(cardInfo.card.setName)
          .font(.headline)
          .multilineTextAlignment(.center)
          .lineLimit(2)
        
        HStack(spacing: 8.0) {
          HStack(alignment: .center, spacing: 3) {
            IconLazyImage(cardInfo.card.resolvedIconURL).frame(width: 20, height: 20)
            Text(cardInfo.card.set.uppercased()).fontWidth(.condensed)
          }
          Text("#\(cardInfo.card.collectorNumber.uppercased())").fontDesign(.serif)
        }
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .font(.caption)
        .fontWeight(.medium)
        
        HStack(spacing: 5) {
          if let usdPrice = cardInfo.card.prices.usd { PillText("$\(usdPrice)").padding(.all, 2) }
          if let usdFoilPrice = cardInfo.card.prices.usdFoil {
            PillText("$\(usdFoilPrice)", isFoil: true).foregroundStyle(.black.opacity(0.8)).padding(.all, 2)
          }
          if let usdEtched = cardInfo.card.prices.usdEtched {
            PillText("$\(usdEtched)", isFoil: true).foregroundStyle(.black.opacity(0.8)).padding(.all, 2)
          }
        }
        .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
        .font(.caption)
        .fontWeight(.medium)
        .monospaced()
        .fixedSize(horizontal: true, vertical: true)
      }
      .opacity(showDetails ? 1.0 : 0.0)
      .animation(.easeOut(duration: 0.4), value: showDetails)
      .frame(width: containerWidth)
      .fixedSize(horizontal: false, vertical: true)
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
            .glassEffectID("grid_button", in: morphNamespace)
        }
        
        if hasScannedCard {
          Button(action: {}) { Image(systemName: "plus").font(.title) }
            .frame(width: 89, height: 89)
            .glassEffect(.clear.interactive())
            .glassEffectID("center_button", in: morphNamespace)
        } else {
          Button(action: {}) { Circle().fill(.white).frame(width: 77, height: 77) }
            .frame(width: 89, height: 89)
            .glassEffect(.clear.interactive())
            .glassEffectID("center_button", in: morphNamespace)
        }
        
        if hasScannedCard {
          Button(action: {}) { Image(systemName: "info").font(.body).frame(width: 55, height: 55) }
            .glassEffect(.clear.interactive())
            .glassEffectID("info_button", in: morphNamespace)
        }
        Spacer()
      }
      .fontWeight(.semibold)
    }
    .padding(.bottom, bottomSafeArea + 80)
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
  
  private func uprightCorners(from frame: CGRect, fallbackSize: CGSize) -> QuadCorners {
    guard frame != .zero else {
      let cardWidth = fallbackSize.width - 110
      let cardHeight = cardWidth / (63.0 / 88.0)
      let midX = fallbackSize.width / 2
      let midY = (fallbackSize.height / 2) - 86.5
      let halfW = cardWidth / 2
      let halfH = cardHeight / 2
      return QuadCorners(
        topLeft: CGPoint(x: midX - halfW, y: midY - halfH),
        topRight: CGPoint(x: midX + halfW, y: midY - halfH),
        bottomRight: CGPoint(x: midX + halfW, y: midY + halfH),
        bottomLeft: CGPoint(x: midX - halfW, y: midY + halfH)
      )
    }
    
    return QuadCorners(
      topLeft: CGPoint(x: frame.minX, y: frame.minY),
      topRight: CGPoint(x: frame.maxX, y: frame.minY),
      bottomRight: CGPoint(x: frame.maxX, y: frame.maxY),
      bottomLeft: CGPoint(x: frame.minX, y: frame.maxY)
    )
  }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}
