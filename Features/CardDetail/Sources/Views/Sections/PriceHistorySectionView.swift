import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct PriceHistorySectionView: View {
  let store: StoreOf<CardDetailFeature>
  let labels: PriceHistoryLabels
  
  var body: some View {
    PriceHistoryView(
      display: store.priceHistory,
      labels: labels,
      onRetry: { store.send(.retryPriceHistoryTapped) }
    )
  }
}
