import DesignComponents
import Networking
import ScryfallKit
import ComposableArchitecture
import SwiftUI

public struct RootView: View {
  @Bindable var store: StoreOf<CardScannerFeature>
  @Namespace private var morphSpace
  
  // Local state for the foil menu
  @State private var selectedFinish: String = "Non-Foil"
  
  public var body: some View {
    NavigationView {
      ZStack(alignment: .bottom) {
        OCRView { result in
          store.send(.didScan(result))
        }
        .background(.white)
        .ignoresSafeArea(.all)
        
        LinearGradient(
          colors: [.black.opacity(0.7), .clear],
          startPoint: .bottom,
          endPoint: .top
        )
        .ignoresSafeArea()
        .frame(height: 230, alignment: .bottom)
        .opacity(store.dataSource?.cardDetails.isEmpty == false ? 1 : 0)
        
        VStack(spacing: 8) {
          if let cardDetails = store.dataSource?.cardDetails, !cardDetails.isEmpty {
            let cardWidth: CGFloat = 183
            let horizontalPadding = (UIScreen.main.bounds.width - cardWidth) / 2
            
            ScrollView(.horizontal, showsIndicators: false) {
              LazyHStack(spacing: 8.0) {
                ForEach(Array(zip(cardDetails, cardDetails.indices)), id: \.0.card.id) { value in
                  let cardInfo = value.0
                  
                  Button(
                    action: {
                      // Optional tap action
                    }, label: {
                      CardView(
                        displayableCard: cardInfo.displayableCardImage,
                        priceVisibility: .hidden,
                        shouldShowShadow: true
                      )
                    }
                  )
                  .frame(width: cardWidth)
                  .buttonStyle(.sinkableButtonStyle)
                  .id(cardInfo.card.id)
                  .scrollTransition(
                    topLeading: .interactive,
                    bottomTrailing: .interactive,
                    axis: .horizontal
                  ) { effect, phase in
                    let opacity = 1.0 - abs(phase.value) * 0.618
                    return effect.opacity(opacity)
                  }
                }
              }
              .scrollTargetLayout()
            }
            .scrollPosition(id: $store.scrolledCardID)
            .scrollTargetBehavior(.viewAligned)
            .safeAreaPadding(.horizontal, horizontalPadding)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .scrollClipDisabled(true)
            .fixedSize(horizontal: false, vertical: true)
            .transition(
              .asymmetric(
                insertion: .scale(scale: 0.01, anchor: .bottom).combined(with: .opacity),
                removal: .scale(scale: 0.01, anchor: .bottom).combined(with: .opacity)
              )
            )
          }
          
          GlassEffectContainer {
            HStack(spacing: 5.0) {
              if let card = store.scrolledCard {
                Text(card.set.uppercased())
                  .font(.subheadline)
                  .fontWidth(.condensed)
                  .frame(minHeight: 44.0)
                  .padding(.horizontal, 16)
                  .lineLimit(1)
                  .glassEffect()
                  .glassEffectID("left_pill", in: morphSpace)
                
                Text(card.name)
                  .font(.headline)
                  .frame(minHeight: 44.0)
                  .padding(.horizontal, 16)
                  .multilineTextAlignment(.center)
                  .lineLimit(1)
                  .glassEffect()
                  .glassEffectID("main_pill", in: morphSpace)
                
                Menu {
                  Button("Main Deck") { /* Add action */ }
                  Button("Sideboard") { /* Add action */ }
                  Button("Collection") { /* Add action */ }
                } label: {
                  Image(systemName: "plus")
                    .frame(minHeight: 44.0)
                    .padding(.horizontal, 16)
                }
                .glassEffect(.regular.interactive())
                .glassEffectID("add_to_pill", in: morphSpace)
              } else {
                Text("Scanning")
                  .font(.subheadline)
                  .frame(minHeight: 44.0)
                  .padding(.horizontal, 24)
                  .glassEffect()
                  .glassEffectID("main_pill", in: morphSpace)
              }
            }
          }
          .animation(.default, value: store.scrolledCardID)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: store.dataSource != nil)
        .padding(.bottom, 13.0)
      }
      .task {
        store.send(.syncCardImageHashDatabase)
      }
    }
  }
  
  public init(store: StoreOf<CardScannerFeature>) {
    self.store = store
  }
}

