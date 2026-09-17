import ComposableArchitecture
import Networking
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  private var scrolledId: UUID?
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 0) {
        // One child store per page the stack has built, not one per card. Scoping the whole
        // collection made a store for every card up front, and TCA notifies every child store on
        // every action, each one re-reading and copying the pager's state: a device trace put that
        // at 4–7 ms of main thread per landed price or variants action with 175 cards. The ids are
        // read here, on the main actor, as a plain array: a lazy stack reads its data during layout
        // off the main actor, where a store collection traps.
        ForEach(Array(store.cards.ids), id: \.self) { id in
          if let page = store.scope(state: \.cards[id: id], action: \.cards[id: id]) {
            CardDetailView(store: page)
              .accessibilityIdentifier("cardDetail.page.\(page.content.card.collectorNumber)")
              .containerRelativeFrame(.horizontal)
              .geometryGroup()
              // Tagged with the card's id so `scrollPosition(id:)` below lands on the tapped card.
              .id(id)
          }
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .accessibilityIdentifier("cardDetail.pager")
    .scrollPosition(id: .constant(scrolledId))
    .edgeScrims()
    .sheet(
      item: $store.scope(state: \.showRulings, action: \.showRulings)
    ) { rulingStore in
      NavigationStack {
        RulingView(store: rulingStore).toolbarTitleDisplayMode(.inline)
      }
    }
  }
  
  public init(store: StoreOf<CardPagerFeature>) {
    self.store = store
    scrolledId = store.selectedId
  }
}
