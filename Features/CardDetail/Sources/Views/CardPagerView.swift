import ComposableArchitecture
import Networking
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  private let scrub: CarouselScrub?
  
  @Environment(\.colorScheme) private var colorScheme

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
            CardDetailView(store: page, scrub: scrub)
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
    .background {
      LandingBackdrop(scrub: scrub)
    }
    .scrollEdgeEffectStyle(.soft, for: .bottom)
    .scrollEdgeEffectHidden(true, for: .top)
    .accessibilityIdentifier("cardDetail.pager")
    .scrollPosition(id: $store.selectedId)
    .onChange(of: store.selectedId, initial: true) { _, newValue in
      scrub?.selectedId = newValue
    }
    .sensoryFeedback(.selection, trigger: store.selectedId)
    .edgeScrims()
    .onGeometryChange(for: CGRect.self) { proxy in
      proxy.frame(in: .global)
    } action: { newValue in
      scrub?.pageFrame = newValue
    }
    .onScrollPhaseChange { _, newPhase in
      guard newPhase == .interacting, let scrub, scrub.isHovering || scrub.isLanding else { return }
      var instant = Transaction()
      instant.disablesAnimations = true
      withTransaction(instant) {
        scrub.isHovering = false
        scrub.endLanding()
      }
    }
    // Read here rather than in the bar: inside the toolbar the environment reports a dark scheme
    // whichever way the phone is set, and the glass's ring came out the same in both.
    .onChange(of: colorScheme, initial: true) { _, newValue in
      scrub?.isLightAppearance = newValue == .light
    }
    .onDisappear {
      scrub?.isHovering = false
      scrub?.endLanding()
    }
    .sheet(
      item: $store.scope(state: \.showRulings, action: \.showRulings)
    ) { rulingStore in
      NavigationStack {
        RulingView(store: rulingStore).toolbarTitleDisplayMode(.inline)
      }
    }
  }
  
  public init(store: StoreOf<CardPagerFeature>, scrub: CarouselScrub? = nil) {
    self.store = store
    self.scrub = scrub
  }
}
