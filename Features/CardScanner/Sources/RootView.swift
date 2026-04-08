import SwiftUI
import DesignComponents
import NukeUI
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
          .ignoresSafeArea(.all)
          
          if let card = store.scrolledCard, let liveCorners = store.latestTrackedCorners {
            let targetCorners = store.isMorphed ? uprightCorners(in: geo) : liveCorners
            
            LazyImage(url: URL(string: card.imageUris?.normal ?? "")) { state in
              if let image = state.image {
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .onAppear {
                    store.send(
                      .imageDownloadCompleted,
                      animation: .spring(response: 0.6, dampingFraction: 0.8)
                    )
                  }
              } else if state.error != nil {
                Color.red.opacity(0.5)
              } else {
                Color.clear
              }
            }
            .frame(width: logicalCardSize.width, height: logicalCardSize.height)
            .projected(to: targetCorners, logicalSize: logicalCardSize)
          }
          
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
