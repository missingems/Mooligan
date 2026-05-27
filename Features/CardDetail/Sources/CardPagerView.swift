import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  @State var isAppeared: Bool = false
  var zoomAnimation: Namespace.ID
  
  private var cardPairs: [(UUID, StoreOf<CardDetailFeature>)] {
    Array(zip(store.cards.ids, store.scope(state: \.cards, action: \.cards)))
  }
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 0) {
        ForEach(cardPairs, id: \.0) { id, childStore in
          CardDetailView(store: childStore)
            .containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $store.selectedId)
    .scrollEdgeEffectHidden()
    .navigationTransition(.zoom(sourceID: store.selectedId ?? UUID(), in: zoomAnimation))
    .sheet(
      item: $store.scope(state: \.showRulings, action: \.showRulings)
    ) { rulingStore in
      NavigationStack {
        RulingView(store: rulingStore).toolbarTitleDisplayMode(.inline)
      }
    }
    .task {
      store.send(.task)
    }
  }
  
  public init(store: StoreOf<CardPagerFeature>, zoomAnimation: Namespace.ID) {
    self.store = store
    self.zoomAnimation = zoomAnimation
  }
}
