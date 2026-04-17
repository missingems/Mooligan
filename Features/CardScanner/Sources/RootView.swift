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
  @State private var bottomSafeArea: CGFloat = 0
  @State private var topSafeArea: CGFloat = 0
  @Namespace private var morphNamespace
  
  @State private var viewSize: CGSize = UIScreen.main.bounds.size
  
  // Cache the last known coordinates so the box can freeze in place while fading out
  @State private var lastValidCorners: QuadCorners? = nil
  
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
          
          // The Overlay wrapped in a Group so we can attach modifiers safely
          Group {
            if let cornersToDraw = store.latestTrackedCorners ?? lastValidCorners,
                let cardInfo = store.dataSource?.cardDetails.first {
              
              let isTracking = store.latestTrackedCorners != nil
              // The exact pixel ratio of a Magic Card to prevent squashing
              let cardSize = CGSize(width: 315, height: 440)
              
              CardView(displayableCard: cardInfo.displayableCardImage, priceVisibility: .hidden)
                .projected(to: cornersToDraw, size: cardSize)
                .ignoresSafeArea()
              // 1. Position Snapping (matches snapDuration: 0.315)
                .animation(.easeOut(duration: 0.315), value: cornersToDraw)
              // 2. Visibility
                .opacity(isTracking ? 1.0 : 0.0)
              // 3. Dynamic Animation (Fade In vs Delayed Fade Out)
                .animation(
                  isTracking
                  ? .easeOut(duration: 0.2)
                  : .easeIn(duration: 0.35).delay(0.6),
                  value: isTracking
                )
            }
          }
          .onChange(of: store.latestTrackedCorners) { oldValue, newValue in
            // Update the cache whenever we get a valid frame
            if let newValue {
              lastValidCorners = newValue
            }
          }
        }
        
        GlassEffectContainer {
          HStack(spacing: 34.0) {
            Spacer()
            
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
