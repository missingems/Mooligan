import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  @State private var scrolledId: UUID?
  
  private struct Page: Identifiable {
    let id: UUID
    let store: StoreOf<CardDetailFeature>
  }
  
  @MainActor private var pages: [Page] {
    store.scope(state: \.cards, action: \.cards).map { Page(id: $0.state.id, store: $0) }
  }
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 0) {
        ForEach(pages) { page in
          CardDetailView(store: page.store)
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
