import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  @State var isAppeared: Bool = false
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 0) {
        ForEach(store.scope(state: \.cards, action: \.cards), id: \.state.id) { childStore in
          CardDetailView(store: childStore)
            .containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $store.selectedId)
    .scrollEdgeEffectHidden()
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
  }
}
