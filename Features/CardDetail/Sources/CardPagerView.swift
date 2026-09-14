import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  @State private var scrolledId: UUID?

  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 0) {
        // Scope a store only for the pages the lazy stack actually builds. Mapping the whole
        // `store.scope(state: \.cards, action: \.cards)` collection created a child store per
        // card, and every child store re-reads its state on every action anywhere in the app,
        // so each swipe's burst of actions cost time proportional to the size of the result set.
        ForEach(store.cards.ids, id: \.self) { id in
          if let cardStore = store.scope(\.cards[id: id], action: \.cards[id: id]) {
            CardDetailView(store: cardStore)
              .containerRelativeFrame(.horizontal)
              .geometryGroup()
              .accessibilityIdentifier("cardDetail.page.\(cardStore.content.card.collectorNumber)")
          }
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .accessibilityIdentifier("cardDetail.pager")
    .scrollPosition(id: $scrolledId)
    .scrollEdgeEffectHidden()
    .onScrollPhaseChange { _, newPhase in
      guard newPhase == .idle else { return }
      store.send(.currentCardSettled(id: scrolledId))
    }
    .edgeScrims()
    .sheet(
      item: $store.scope(state: \.showRulings, action: \.showRulings)
    ) { rulingStore in
      NavigationStack {
        RulingView(store: rulingStore).toolbarTitleDisplayMode(.inline)
      }
    }
    .task {
      store.send(.viewAppeared)
    }
  }
  
  public init(store: StoreOf<CardPagerFeature>) {
    self.store = store
    _scrolledId = State(initialValue: store.selectedId)
  }
}
