import ComposableArchitecture
import Networking
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  private var scrolledId: UUID?
  
  public var body: some View {
    let _ = Self._printChanges() // Debugging changes
    ScrollView(.horizontal, showsIndicators: false) {
      CardPages(store: store)
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
