import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct CardGridContentView: View {
  @Bindable var store: StoreOf<QueryFeature>
  let dataSource: CardDataSource
  let cardSize: CGSize
  var zoomAnimation: Namespace.ID
  
  var body: some View {
    ForEach(Array(zip(dataSource.cardDetails, dataSource.cardDetails.indices)), id: \.0.card.id) { value in
      let cardInfo = value.0
      let index = value.1
      
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
        .frame(
          width: cardSize.width > 0 ? cardSize.width : nil,
          height: cardSize.height > 0 ? cardSize.height : nil
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
