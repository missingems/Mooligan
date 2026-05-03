import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct CardPagerView: View {
  @Bindable var store: StoreOf<CardPagerFeature>
  
  private var cardPairs: [(UUID, StoreOf<CardDetailFeature>)] {
    Array(zip(store.cards.ids, store.scope(state: \.cards, action: \.cards)))
  }
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 0) {
        ForEach(cardPairs, id: \.0) { id, childStore in
          DeferredCardDetailView(store: childStore)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $store.selectedId)
    .navigationTitle(
      store.cards[id: store.selectedId ?? UUID()]?.content.card.name ?? ""
    )
    .navigationBarTitleDisplayMode(.inline)
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

private struct DeferredCardDetailView: View {
  let store: StoreOf<CardDetailFeature>
  @State private var isReady = false
  
  var body: some View {
    ZStack {
      if isReady {
        CardDetailView(store: store)
      }
    }
    .containerRelativeFrame(.horizontal)
    .task { isReady = true }
  }
}
