import SwiftUI
import DesignComponents
import Nuke
import ScryfallKit
import ComposableArchitecture
import VariableBlur

public struct RootView: View {
  @Bindable var store: StoreOf<CardScannerFeature>
  @State private var bottomSafeArea: CGFloat = 0
  @State private var topSafeArea: CGFloat = 0
  @Namespace private var morphNamespace // ✨ Add this
  
  public var body: some View {
    NavigationView {
      GeometryReader { geo in
        let dynamicWidth = geo.size.width - 110
        let dynamicHeight = dynamicWidth * 1.4
        let dynamicCardSize = CGSize(width: dynamicWidth, height: dynamicHeight)
        let hasScannedCard = store.dataSource != nil
        
        ZStack(alignment: .bottom) {
            
          ZStack(alignment: .topLeading) {
            
            OCRView(
              isMorphed: store.isMorphed,
              onValidatedScan: { result in store.send(.didScan(result)) },
              onTrackingUpdate: { corners in store.send(.trackingCornersUpdated(corners)) }
            )
            .background(.black)
            VariableBlurView(maxBlurRadius: 10, direction: .blurredTopClearBottom)
              .frame(height: topSafeArea + 64 )
              .offset(y:-10)
            
            ScrollView(.horizontal) {
              LazyHStack(spacing: 8) {
                if let cardDetails = store.dataSource?.cardDetails {
                  let containerWidth = dynamicCardSize.width
                  let spacing: CGFloat = 8
                  let horizontalPadding = (geo.size.width - containerWidth) / 2
                  let liveCorners = store.latestTrackedCorners ?? uprightCorners(in: geo, cardSize: dynamicCardSize)
                  
                  ForEach(Array(zip(cardDetails, cardDetails.indices)), id: \.0.card.id) { value in
                    let cardInfo = value.0
                    let index = value.1
                    
                    // 1. Simplify conditions
                    let isFirst = index == 0
                    let isScanning = isFirst && !store.isMorphed
                    let screenOffsetX = horizontalPadding + CGFloat(index) * (containerWidth + spacing)
                    
                    // 2. EXPLICITLY type these variables to relieve the type-checker
                    let targetCorners: QuadCorners = isScanning
                    ? translate(liveCorners, byX: -screenOffsetX)
                    : uprightCorners(in: geo, cardSize: dynamicCardSize)
                    
                    let detailsOpacity: Double = isScanning ? 0.0 : 1.0
                    let cardAnimation: Animation? = isFirst ? .bouncy : nil
                    let cardZIndex: Double = isFirst ? 1.0 : 0.0
                    
                    VStack(spacing: 13.0) {
                      CardView(
                        displayableCard: cardInfo.displayableCardImage,
                        priceVisibility: .hidden,
                        shouldShowShadow: true
                      )
                      .frame(width: dynamicCardSize.width, height: dynamicCardSize.height)
                      
                      VStack(alignment: .center, spacing: 5.0) {
                        Text(cardInfo.card.setName)
                          .font(.headline)
                          .multilineTextAlignment(.center)
                          .lineLimit(2)
                        
                        HStack(spacing: 8.0) {
                          HStack(alignment: .center, spacing: 3) {
                            IconLazyImage(cardInfo.card.resolvedIconURL).frame(width: 20, height: 20)
                            
                            Text(cardInfo.card.set.uppercased())
                              .fontWidth(.condensed)
                          }
                           
                          Text("#\(cardInfo.card.collectorNumber.uppercased())")
                            .fontDesign(.serif)
                        }
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .font(.caption)
                        .fontWeight(.medium)
                        
                        HStack(spacing: 5) {
                          if let usdPrice = cardInfo.card.prices.usd {
                            PillText("$\(usdPrice)")
                              .padding(.all, 2)
                              .glassEffect(.regular, in: .rect(cornerSize: CGSize(width: 10, height: 10)))
                          }
                          
                          if let usdFoilPrice = cardInfo.card.prices.usdFoil {
                            PillText("$\(usdFoilPrice)", isFoil: true)
                              .foregroundStyle(.black.opacity(0.8))
                              .padding(.all, 2)
                              .glassEffect(.regular, in: .rect(cornerSize: CGSize(width: 10, height: 10)))
                          }
                          
                          if let usdEtched = cardInfo.card.prices.usdEtched {
                            PillText("$\(usdEtched)", isFoil: true)
                              .foregroundStyle(.black.opacity(0.8))
                              .padding(.all, 2)
                              .glassEffect(.regular, in: .rect(cornerSize: CGSize(width: 10, height: 10)))
                          }
                        }
                        .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospaced()
                        .fixedSize(horizontal: true, vertical: true)
                      }
                      .frame(width: dynamicCardSize.width)
                      .fixedSize(horizontal: false, vertical: true)
                      .opacity(detailsOpacity) // ✨ Uses explicitly typed Double
                    }
                    .frame(width: dynamicCardSize.width)
                    .fixedSize(horizontal: false, vertical: true)
                    .projected(to: targetCorners, logicalSize: dynamicCardSize)
                    .animation(cardAnimation, value: store.isMorphed) // ✨ Uses explicitly typed Animation?
                    .zIndex(cardZIndex) // ✨ Uses explicitly typed Double
                    .frame(width: containerWidth, height: geo.size.height, alignment: .topLeading)
                  }
                }
              }
              .padding(.horizontal, (geo.size.width - dynamicCardSize.width) / 2)
              .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .frame(width: geo.size.width, height: geo.size.height)
            .background {
              Rectangle()
                .fill(.black.opacity(0.619))
                .opacity(store.isMorphed ? 1 : 0)
                .animation(.default, value: store.isMorphed)
            }
          }
          
          VariableBlurView(maxBlurRadius: 15, direction: .blurredBottomClearTop).frame(height: bottomSafeArea + 64)
          
          GlassEffectContainer {
            HStack(spacing: 34.0) {
              Spacer()
              
              // LEFT BUTTON
              if hasScannedCard {
                Button(action: {
                }) {
                  Image(systemName: "square.grid.2x2.fill")
                    .font(.body)
                    .frame(width: 55, height: 55)
                }
                .glassEffect(.clear.interactive())
                .glassEffectID("grid_button", in: morphNamespace) // ✨
              }
              
              // CENTER BUTTON (True morphing using shared ID)
              if hasScannedCard {
                Button(action: {
                }) {
                  Image(systemName: "plus")
                    .font(.title)
                    .frame(width: 89, height: 89)
                }
                .glassEffect(.clear.interactive())
                .glassEffectID("center_button", in: morphNamespace) // ✨ Shares ID
              } else {
                Button(action: {
                }) {
                  Circle().fill(.white)
                    .frame(width: 83, height: 83)
                    .padding(.all, 6.0)
                }
                .glassEffect(.clear.interactive())
                .glassEffectID("center_button", in: morphNamespace) // ✨ Shares ID
              }
              
              // RIGHT BUTTON
              if hasScannedCard {
                Button(action: {
                }) {
                  Image(systemName: "info")
                    .font(.body)
                    .frame(width: 55, height: 55)
                }
                .glassEffect(.clear.interactive())
                .glassEffectID("info_button", in: morphNamespace) // ✨
              }
              
              Spacer()
            }
            .fontWeight(.semibold)
          }
          .padding(.bottom, bottomSafeArea + 80)
          // ✨ Drive the layout shift for the namespace to animate
          .animation(.bouncy(duration: 0.5, extraBounce: 0.1), value: hasScannedCard)
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { print("Bug button tapped") }) {
            Image(systemName: "ladybug.fill")
          }
        }
        
        ToolbarItem(id: "info", placement: .principal) {
          Text(store.status.displayTitle)
            .font(.headline)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
          if store.dataSource != nil {
            Button(role: .close) {
              store.send(.resetScan)
            }
          }
        }
      }
      .ignoresSafeArea(.all)
      .task { store.send(.syncCardImageHashDatabase) }
      .onAppear {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
          bottomSafeArea = window.safeAreaInsets.bottom
          topSafeArea = window.safeAreaInsets.top
        }
      }
    }
    .colorScheme(.dark)
  }
  
  // ✨ UPDATE CORNERS FUNCTION: Now accepts the dynamic card size as a parameter
  private func uprightCorners(in geo: GeometryProxy, cardSize: CGSize) -> QuadCorners {
    let midX = cardSize.width / 2
    let midY = geo.size.height * 0.4
    
    let halfW = cardSize.width / 2
    let halfH = cardSize.height / 2
    
    return QuadCorners(
      topLeft: CGPoint(x: midX - halfW, y: midY - halfH),
      topRight: CGPoint(x: midX + halfW, y: midY - halfH),
      bottomRight: CGPoint(x: midX + halfW, y: midY + halfH),
      bottomLeft: CGPoint(x: midX - halfW, y: midY + halfH)
    )
  }
  
  private func translate(_ corners: QuadCorners, byX dx: CGFloat) -> QuadCorners {
    return QuadCorners(
      topLeft: CGPoint(x: corners.topLeft.x + dx, y: corners.topLeft.y),
      topRight: CGPoint(x: corners.topRight.x + dx, y: corners.topRight.y),
      bottomRight: CGPoint(x: corners.bottomRight.x + dx, y: corners.bottomRight.y),
      bottomLeft: CGPoint(x: corners.bottomLeft.x + dx, y: corners.bottomLeft.y)
    )
  }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}
