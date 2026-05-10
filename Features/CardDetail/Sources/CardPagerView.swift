import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  @State var isAppeared: Bool = false
  
  private var cardPairs: [(UUID, StoreOf<CardDetailFeature>)] {
    Array(zip(store.cards.ids, store.scope(state: \.cards, action: \.cards)))
  }
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      if isAppeared {
        LazyHStack(spacing: 0) {
          ForEach(cardPairs, id: \.0) { _, childStore in
            CardDetailView(store: childStore)
              .containerRelativeFrame(.horizontal)
          }
        }
        .scrollTargetLayout()
      }
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $store.selectedId)
    .scrollEdgeEffectHidden()
    .onAppear {
      isAppeared = true
    }
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
  }
}
