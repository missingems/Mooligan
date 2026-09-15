import ComposableArchitecture
import Networking
import SwiftUI

struct CardPages: View {
  let store: StoreOf<CardPagerFeature>

  private struct Page: Identifiable {
    let id: UUID
    let store: StoreOf<CardDetailFeature>
  }

  var body: some View {
    LazyHStack(spacing: 0) {
      // Ids come from the collection, so building the list doesn't copy each card's state.
      ForEach(Array(zip(store.cards.ids, store.scope(state: \.cards, action: \.cards)).map { Page(id: $0, store: $1) })) { page in
        CardDetailView(store: page.store)
          .containerRelativeFrame(.horizontal)
          .geometryGroup()
          .accessibilityIdentifier("cardDetail.page.\(page.store.content.card.collectorNumber)")
      }
    }
    .scrollTargetLayout()
  }
}
