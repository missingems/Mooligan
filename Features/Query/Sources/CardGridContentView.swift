import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct CardGridContentView: View {
  @Bindable var store: StoreOf<QueryFeature>
  var layoutConfiguration: CardView.LayoutConfiguration
  
  var body: some View {
    if let dataSource = store.dataSource {
      ForEach(Array(dataSource.cardDetails.enumerated()), id: \.element.card.id) { index, cardInfo in
        CardGridCell(
          cardInfo: cardInfo,
          layoutConfiguration: layoutConfiguration,
          isScrollable: store.mode.isScrollable,
          onSelect: { store.send(.didSelectCard(cardInfo.card, store.queryType)) }
        )
//        .task {
//          if store.state.shouldLoadMore(at: index) {
//            store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
//          }
//        }
      }
    }
  }
}

struct CardGridCell: View {
  let cardInfo: CardInfo
  let layoutConfiguration: CardView.LayoutConfiguration
  let isScrollable: Bool
  let onSelect: () -> Void
  
  var body: some View {
    CardView(
      displayableCard: cardInfo.displayableCardImage,
      layoutConfiguration: layoutConfiguration,
      callToActionHorizontalOffset: -3.0,
      priceVisibility: .display(usdFoil: cardInfo.displayPriceUSDFoil, usd: cardInfo.displayPriceUSD),
      shadowConfiguration: .custom(color: Color(.sRGBLinear, white: 0, opacity: 0.33), radius: 3.0, offset: CGPoint(x: 0, y: 3.0))
    )
    // 1. Tag the view for the zoom transition using the card's ID
    // 2. Ensure the entire frame registers the tap, even if there are transparent gaps
    .contentShape(Rectangle())
    // 3. Fire the action cleanly without interrupting the scroll
    .onTapGesture { onSelect() }
    // 4. Disable tapping if the grid is not meant to be scrollable/interactive right now
    .disabled(!isScrollable)
  }
}
