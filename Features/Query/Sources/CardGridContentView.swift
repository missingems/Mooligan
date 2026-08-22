import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct CardGridContentView: View {
  @Bindable var store: StoreOf<QueryFeature>
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.displayScale) private var displayScale
  var zoomAnimation: Namespace.ID
  var layoutConfiguration: CardView.LayoutConfiguration
  
  var body: some View {
    if let dataSource = store.dataSource {
      ForEach(Array(dataSource.cardDetails.enumerated()), id: \.element.card.id) { index, cardInfo in
        Button {
          store.send(.didSelectCard(cardInfo.card, store.queryType))
        } label: {
          ZStack(alignment: .top) {
            Color.clear
              .overlay(
                RoundedRectangle(cornerRadius: layoutConfiguration.cornerRadius)
                  .stroke(
                    (
                      colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225)).blendMode(
                      colorScheme == .dark ? .plusLighter : .plusDarker
                    ),
                    lineWidth: 1 / displayScale
                  )
              )
              .frame(width: layoutConfiguration.size.width, height: layoutConfiguration.size.height, alignment: .center)
            
            CardView(
              displayableCard: cardInfo.displayableCardImage,
              layoutConfiguration: layoutConfiguration,
              callToActionHorizontalOffset: -3.0,
              priceVisibility: .display(usdFoil: cardInfo.displayPriceUSDFoil, usd: cardInfo.displayPriceUSD),
              shadowConfiguration: .custom(color: Color(.sRGBLinear, white: 0, opacity: 0.33), radius: 3.0, offset: CGPoint(x: 0, y: 3.0)),
              send: { action in
                if action == .toggledFaceDirection {
                  store.send(.cardFaceToggled(id: cardInfo.card.id))
                }
              }
            )
            .geometryGroup()
            .matchedTransitionSource(id: cardInfo.card.id, in: zoomAnimation)
          }
        }
        .disabled(store.mode.isScrollable == false)
        .buttonStyle(.sinkableButtonStyle)
        .task {
          if store.state.shouldLoadMore(at: index) {
            store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
          }
        }
      }
    }
  }
}
