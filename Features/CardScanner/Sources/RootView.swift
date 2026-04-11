import SwiftUI
import DesignComponents
import Nuke
import ScryfallKit
import ComposableArchitecture

public struct RootView: View {
  @Bindable var store: StoreOf<CardScannerFeature>
  
  private let logicalCardSize = CGSize(width: 250, height: 350)
  private let finalMorphedSize = CGSize(width: 320, height: 448)
  
  public var body: some View {
    NavigationView {
      GeometryReader { geo in
        ZStack(alignment: .bottom) {
          ZStack(alignment: .topLeading) {
            OCRView(
              isMorphed: store.isMorphed,
              onValidatedScan: { result in store.send(.didScan(result)) },
              onTrackingUpdate: { corners in store.send(.trackingCornersUpdated(corners)) }
            )
            .background(.black)
            
            ScrollView(.horizontal) {
              HStack(spacing: 8) {
                // 1. SAFETY FALLBACK: Removed `liveCorners` from this guard statement.
                // We MUST render this view if `scrolledCard` exists, no matter what.
                if let card = store.scrolledCard {
                  if let cardDetails = store.dataSource?.cardDetails {
                    
                    let containerWidth = finalMorphedSize.width
                    let spacing: CGFloat = 8
                    let horizontalPadding = (geo.size.width - containerWidth) / 2
                    
                    // 2. DEFAULT CORNERS: If the camera drops tracking before the lock engages,
                    // safely default to the upright center so the view doesn't vanish.
                    let liveCorners = store.latestTrackedCorners ?? uprightCorners(in: geo)
                    
                    ForEach(Array(zip(cardDetails, cardDetails.indices)), id: \.0.card.id) { value in
                      let _card = value.0
                      let index = value.1
                      
                      let screenOffsetX = horizontalPadding + CGFloat(index) * (containerWidth + spacing)
                      let adjustedLiveCorners = translate(liveCorners, byX: -screenOffsetX)
                      let targetCorners = store.isMorphed ? uprightCorners(in: geo) : adjustedLiveCorners
                      
                      // MARK: - VStack Layout Fix
                      VStack(spacing: 16) {
                        CardView(
                          displayableCard: _card.displayableCardImage,
                          priceVisibility: .hidden,
                          shouldShowShadow: true
                        )
                        // 3. Lock the card size specifically so it never shrinks
                        .frame(width: logicalCardSize.width, height: logicalCardSize.height)
                        
                        // 4. Hide text smoothly using opacity
                        Text("why")
                          .font(.headline)
                          .opacity(store.isMorphed ? 1 : 0)
                      }
                      // 5. Allow the VStack to grow naturally without compressing children
                      .fixedSize()
                      // 6. Project the entire stack to the tracked corners
                      .projected(to: targetCorners, logicalSize: logicalCardSize)
                      .animation(.bouncy, value: store.isMorphed)
                      .frame(width: containerWidth, height: geo.size.height, alignment: .topLeading)
                    }
                  }
                }
              }
              .padding(.horizontal, (geo.size.width - finalMorphedSize.width) / 2)
              .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(.ultraThickMaterial.opacity(store.isMorphed ? 1 : 0))
            .animation(.default, value: store.isMorphed)
          }
        }
      }
      .toolbar {
        // Top Left Bug Button
        ToolbarItem(placement: .topBarLeading) {
          Button(action: {
            // Action to handle bug report or debug tools
            print("Bug button tapped")
          }) {
            Image(systemName: "ladybug.fill")
          }
        }
        
        // Center Status
        ToolbarItem(id: "info", placement: .principal) {
          Text(store.status.displayTitle)
            .font(.headline)
        }
        
        // Right Close Button
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
    }
    .colorScheme(.dark)
  }
  
  private func uprightCorners(in geo: GeometryProxy) -> QuadCorners {
    let midX = finalMorphedSize.width / 2
    let midY = geo.size.height / 2
    let halfW = finalMorphedSize.width / 2
    let halfH = finalMorphedSize.height / 2
    
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

// MARK: - View Modifiers

struct RandomFloatingModifier: ViewModifier {
  let isMorphed: Bool
  @State private var floatingOffset: CGFloat = 0
  
  func body(content: Content) -> some View {
    content
      .offset(y: floatingOffset)
      .onChange(of: isMorphed, initial: true) { _, morphed in
        if morphed {
          let randomDuration = Double.random(in: 1.8...3.0)
          let randomDelay = Double.random(in: 0.0...1.5)
          let randomDistance = CGFloat.random(in: 8...15)
          let randomDirection: CGFloat = Bool.random() ? 1 : -1
          
          withAnimation(
            .easeInOut(duration: randomDuration)
            .repeatForever(autoreverses: true)
            .delay(randomDelay)
          ) {
            floatingOffset = randomDistance * randomDirection
          }
        } else {
          withAnimation(.easeOut(duration: 0.2)) {
            floatingOffset = 0
          }
        }
      }
  }
}

extension View {
  func randomFloating(isMorphed: Bool) -> some View {
    modifier(RandomFloatingModifier(isMorphed: isMorphed))
  }
}
