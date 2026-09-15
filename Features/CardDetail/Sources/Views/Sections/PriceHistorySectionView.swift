import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct PriceHistorySectionView: View {
  let store: StoreOf<CardDetailFeature>
  let labels: PriceHistoryLabels
  
  var body: some View {
    let _ = Self._printChanges()
    PriceHistoryView(
      display: store.priceHistory,
      purchaseDropdown: store.purchaseDropdown,
      labels: labels,
      onRetry: { store.send(.retryPriceHistoryTapped) },
      onPurchaseLinksRequested: { store.send(.purchaseLinksRequested) }
    )
  }
}
