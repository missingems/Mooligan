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
    TabView(selection: $store.selectedId) {
      ForEach(cardPairs, id: \.0) { id, childStore in
        CardDetailView(store: childStore)
          .tag(id) // Required to sync the selectedId with the TabView
      }
    }
    // Use .page(indexDisplayMode: .never) if you want to hide the page indicator dots,
    // which matches your original `showsIndicators: false`.
    .tabViewStyle(.page(indexDisplayMode: .never))
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
