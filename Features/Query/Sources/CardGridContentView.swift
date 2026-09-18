import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct CardGridContentView: View {
  @Bindable var store: StoreOf<QueryFeature>
  var layoutConfiguration: CardLayoutConfiguration
  
  var body: some View {
    ForEach(Array(store.dataSource.cardDetails.enumerated()), id: \.element.card.id) { index, cardInfo in
      CardView(
        displayableCard: cardInfo.displayableCardImage,
        layoutConfiguration: layoutConfiguration,
        callToActionHorizontalOffset: -3.0,
        priceVisibility: .display(
          usdFoil: cardInfo.displayPriceUSDFoil,
          usd: cardInfo.displayPriceUSD
        ),
        send: { _ in
          store.send(.cardFaceToggled(id: cardInfo.id))
        }
      )
      // A page landing or a search keystroke writes the store, which re-runs this whole grid; the
      // comparison keeps cards whose inputs did not change from rebuilding their image.
      .equatable()
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("setDetail.card.\(cardInfo.card.collectorNumber)")
      .onTapGesture {
        store.send(
          .didSelectCard(cardInfo.card, store.queryType)
        )
      }
      .task {
        if store.state.shouldLoadMore(at: index) {
          store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
        }
      }
    }
  }
}
