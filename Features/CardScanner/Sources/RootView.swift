import SwiftUI
import DesignComponents
import Nuke
import ScryfallKit
import ComposableArchitecture
import VariableBlur
import Foundation
import UIKit
import Networking

// ✨ ADDED: The math modifier to map 4 corners to standard SwiftUI transforms
public struct QuadOverlayModifier: ViewModifier {
  public let corners: QuadCorners
  
  public func body(content: Content) -> some View {
    // 1. Calculate width and height using the distance formula
    let width = distance(corners.topLeft, corners.topRight)
    let height = distance(corners.topLeft, corners.bottomLeft)
    
    // 2. Calculate the center point of the 4 corners
    let center = CGPoint(
      x: (corners.topLeft.x + corners.topRight.x + corners.bottomLeft.x + corners.bottomRight.x) / 4,
      y: (corners.topLeft.y + corners.topRight.y + corners.bottomLeft.y + corners.bottomRight.y) / 4
    )
    
    // 3. Calculate the rotation angle based on the top edge
    let angle = atan2(corners.topRight.y - corners.topLeft.y, corners.topRight.x - corners.topLeft.x)
    
    // 4. Apply the transforms
    content
      .frame(width: width, height: height)
      .rotationEffect(.radians(Double(angle)))
      .position(center)
    // Interactive spring smooths out the jitter from the live camera feed
      .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: center)
  }
  
  private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    hypot(p2.x - p1.x, p2.y - p1.y)
  }
}

public extension View {
  func trackCorners(_ corners: QuadCorners?) -> some View {
    Group {
      if let corners = corners {
        self.modifier(QuadOverlayModifier(corners: corners))
      } else {
        self.hidden()
      }
    }
  }
}

// MARK: - Views

public struct RootView: View {
  @Bindable var store: StoreOf<CardScannerFeature>
  @State private var bottomSafeArea: CGFloat = 0
  @State private var topSafeArea: CGFloat = 0
  @Namespace private var morphNamespace
  
  @State private var viewSize: CGSize = UIScreen.main.bounds.size
  
  public var body: some View {
    NavigationView {
      let hasScannedCard = store.dataSource != nil
      ZStack(alignment: .bottom) {
        ZStack(alignment: .center) {
          OCRView(
            isMorphed: store.isScanningPaused,
            onValidatedScan: { result in store.send(.didScan(result)) },
            onTrackingUpdate: { corners in store.send(.trackingCornersUpdated(corners)) }
          )
          .background(.black)
          
          // ✨ ADDED: The live AR tracking overlay
          if !store.isMorphed, let corners = store.latestTrackedCorners {
            // Replace "card_back" with your actual placeholder or a downloaded UI image
            Image("card_back")
              .resizable()
              .scaledToFill()
              .clipShape(RoundedRectangle(cornerRadius: 12)) // Standard MTG corner radius
              .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
              .trackCorners(corners)
              .transition(.opacity)
          }
          
          ScrollView(.horizontal) {
            HStack(spacing: 8) {
              if let cardDetails = store.dataSource?.cardDetails {
                let containerWidth = viewSize.width - 110
                
                ForEach(Array(cardDetails.enumerated()), id: \.element.card.id) { index, cardInfo in
                  
                  let isFirst = index == 0
                  let isScanning = isFirst && !store.isMorphed
                  
                  let detailsOpacity: Double = isScanning ? 0.0 : 1.0
                  
                  // Calculate the proper ratio size for this specific card
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
                        }
                        
                        if let usdFoilPrice = cardInfo.card.prices.usdFoil {
                          PillText("$\(usdFoilPrice)", isFoil: true)
                            .foregroundStyle(.black.opacity(0.8))
                            .padding(.all, 2)
                        }
                        
                        if let usdEtched = cardInfo.card.prices.usdEtched {
                          PillText("$\(usdEtched)", isFoil: true)
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
                    .opacity(detailsOpacity) // Applying opacity based on scan state
                    .frame(width: containerWidth)
                    .fixedSize(horizontal: false, vertical: true)
                  }
                }
              }
            }
            .padding(.horizontal, 55)
            .scrollTargetLayout()
          }
          .scrollTargetBehavior(.viewAligned)
          .scrollIndicators(.hidden)
          .offset(y: -40)
        }
        
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
              .glassEffectID("grid_button", in: morphNamespace)
            }
            
            // CENTER BUTTON
            if hasScannedCard {
              Button(action: {
              }) {
                Image(systemName: "plus")
                  .font(.title)
                  .frame(width: 89, height: 89)
              }
              .glassEffect(.clear.interactive())
              .glassEffectID("center_button", in: morphNamespace)
            } else {
              Button(action: {
              }) {
                Circle().fill(.white)
                  .frame(width: 83, height: 83)
                  .padding(.all, 6.0)
              }
              .glassEffect(.clear.interactive())
              .glassEffectID("center_button", in: morphNamespace)
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
              .glassEffectID("info_button", in: morphNamespace)
            }
            
            Spacer()
          }
          .fontWeight(.semibold)
        }
        .padding(.bottom, bottomSafeArea + 80)
        .animation(.bouncy(duration: 0.5, extraBounce: 0.1), value: hasScannedCard)
      }
      .onGeometryChange(for: CGSize.self, of: { proxy in
        proxy.size
      }, action: { newValue in
        self.viewSize = newValue
      })
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
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}
