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
        // Eagerly materialised: LazyHStack indexes its children off the main
        // actor, and _StoreCollection's subscript requires main.
        ForEach(Array(store.scope(state: \.cards, action: \.cards)), id: \.state.id) { childStore in
          CardDetailView(store: childStore)
            .containerRelativeFrame(.horizontal)
            .geometryGroup()
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
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
