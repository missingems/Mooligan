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
            HStack(spacing: 0) {
              if let card = store.scrolledCard, let liveCorners = store.latestTrackedCorners {
                let targetCorners = store.isMorphed ? uprightCorners(in: geo) : liveCorners
                
                if let sendableImage = store.downloadedCardImage {
                  ZStack(alignment: .topLeading) {
                    CardView(displayableCard: card.displayableCardImage, priceVisibility: .hidden)
                      .frame(width: logicalCardSize.width, height: logicalCardSize.height)
                      .projected(to: liveCorners, logicalSize: logicalCardSize)
                  }
                  // 4. Force this "page" in the ScrollView to match the exact screen size
                  .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                  
                }
              }
            }
          }
          .frame(width: geo.size.width, height: geo.size.height)
          
          VStack {
            Spacer()
            HStack {
              Spacer()
              Button(action: {
                if store.isMorphed {
                  store.send(.resetScan, animation: .spring)
                } else {
                  print("Blank circle pressed")
                }
              }) {
                Circle().fill(.white)
                  .frame(width: 83, height: 83)
              }
              .padding(.all, 6)
              Spacer()
            }
            .padding(.bottom, 34)
          }
          .zIndex(10)
        }
      }
      .ignoresSafeArea(.all)
      .task { store.send(.syncCardImageHashDatabase) }
    }
  }
  
  private func uprightCorners(in geo: GeometryProxy) -> QuadCorners {
    let midX = geo.size.width / 2
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
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}
