import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct CardGridContentView: View {
  @Bindable var store: StoreOf<QueryFeature>
  let cardSize: CGSize
  var zoomAnimation: Namespace.ID
  
  var body: some View {
    if let dataSource = store.dataSource {
      ForEach(Array(dataSource.cardDetails.enumerated()), id: \.element.card.id) { index, cardInfo in
        Button {
          store.send(.didSelectCard(cardInfo.card, store.queryType))
        } label: {
          CardView(
            displayableCard: cardInfo.displayableCardImage,
            layoutConfiguration: .init(rotation: .portrait, maxWidth: cardSize.width),
            callToActionHorizontalOffset: -3.0,
            priceVisibility: .display(usdFoil: cardInfo.displayPriceUSDFoil, usd: cardInfo.displayPriceUSD),
            shouldShowShadow: false,
            send: { action in
              if action == .toggledFaceDirection {
                store.send(.cardFaceToggled(id: cardInfo.card.id))
              }
            }
          )
          .matchedTransitionSource(id: cardInfo.card.id, in: zoomAnimation)
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
