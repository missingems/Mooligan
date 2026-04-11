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
        ZStack(alignment: .topLeading) {
          OCRView(
            isMorphed: store.isMorphed,
            onValidatedScan: { result in store.send(.didScan(result)) },
            onTrackingUpdate: { corners in store.send(.trackingCornersUpdated(corners)) }
          )
          .background(.black)
          
          ScrollView(.horizontal) {
            HStack(spacing: 16) {
              if let card = store.scrolledCard, let liveCorners = store.latestTrackedCorners {
                if let cardDetails = store.dataSource?.cardDetails {
                  
                  let containerWidth = finalMorphedSize.width
                  let spacing: CGFloat = 16
                  let horizontalPadding = (geo.size.width - containerWidth) / 2
                  
                  ForEach(Array(zip(cardDetails, cardDetails.indices)), id: \.0.card.id) { value in
                    let _card = value.0
                    let index = value.1
                    
                    let screenOffsetX = horizontalPadding + CGFloat(index) * (containerWidth + spacing)
                    let adjustedLiveCorners = translate(liveCorners, byX: -screenOffsetX)
                    let targetCorners = store.isMorphed ? uprightCorners(in: geo) : adjustedLiveCorners
                    
                    let isMainCard = (_card.card.id == card.card.id) && (store.downloadedCardImage != nil)
                    
                    ZStack(alignment: .top) {
                      
                      // 1. The Card
                      CardView(displayableCard: _card.displayableCardImage, priceVisibility: .hidden, shouldShowShadow: true)
                        .frame(width: logicalCardSize.width, height: logicalCardSize.height)
                        .projected(to: targetCorners, logicalSize: logicalCardSize)
                        .animation(.bouncy, value: store.isMorphed)
                        .frame(width: containerWidth, height: geo.size.height, alignment: .topLeading)
                      
                      // 2. The Text Detail Label (Now only Set / Collector Number)
                      if store.isMorphed {
                        let setName = _card.card.setName ?? _card.card.set.uppercased()
                        
                        Text("\(setName) • #\(_card.card.collectorNumber)")
                          .font(.headline)
                          .lineLimit(1)
                          .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                          .glassEffect(.regular)
                          .offset(y: (geo.size.height / 2) + (finalMorphedSize.height / 2) + 24)
                      }
                    }
                    .zIndex(isMainCard ? 1 : 0)
                    .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                      content
                        .rotation3DEffect(
                          .degrees(phase.value * -15),
                          axis: (x: 0, y: 1, z: 0),
                          perspective: 0.6
                        )
                        .scaleEffect(phase.isIdentity ? 1 : 0.95)
                    }
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
        }
      }
      .toolbar {
        // Center Status - Now ALWAYS displays the state or the Card Title
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
      .preferredColorScheme(.dark)
      .task { store.send(.syncCardImageHashDatabase) }
    }
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
