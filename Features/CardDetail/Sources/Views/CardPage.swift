import ComposableArchitecture
import Networking
import SwiftUI

/// One page of the card pager.
struct CardPage: View {
  let store: StoreOf<CardPagerFeature>
  let id: UUID

  var body: some View {
    // Always one view, found or not, so the lazy stack can count its pages without building them.
    // Cards are never removed from the pager, so the lookup only misses in theory.
    ZStack {
      if let card = store.scope(state: \.cards[id: id], action: \.cards[id: id]) {
        CardDetailView(store: card)
          .accessibilityIdentifier("cardDetail.page.\(card.content.card.collectorNumber)")
      }
    }
    .containerRelativeFrame(.horizontal)
    .geometryGroup()
  }
}
