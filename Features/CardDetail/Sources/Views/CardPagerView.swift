import ComposableArchitecture
import Networking
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  private var scrolledId: UUID?
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 0) {
        // The collection scoped straight into `ForEach`, as TCA recommends, each element a child
        // store identified by its object identity. Eagerly turned into an `Array`: a lazy stack reads
        // the collection during layout off the main actor, and TCA traps on a store collection
        // touched there. Each page is sized to the pager, not to its content — an unbounded width
        // proposal let a page's card grow to fill whatever the widest section wanted.
        ForEach(Array(store.scope(state: \.cards, action: \.cards))) { card in
          ZStack {
            CardDetailView(store: card)
              .accessibilityIdentifier("cardDetail.page.\(card.content.card.collectorNumber)")
          }
          .containerRelativeFrame(.horizontal)
          .geometryGroup()
          // Scoped stores are identified by object identity, which `scrollPosition(id:)` below
          // cannot be asked for, so each page is tagged with its card's id to land on the tapped card.
          .id(card.content.card.id)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .accessibilityIdentifier("cardDetail.pager")
    .scrollPosition(id: .constant(scrolledId))
    .scrollEdgeEffectHidden()
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
    scrolledId = store.selectedId
  }
}
