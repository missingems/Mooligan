import ComposableArchitecture
import Networking
import SwiftUI

struct CardPages: View {
  let store: StoreOf<CardPagerFeature>

  var body: some View {
    LazyHStack(spacing: 0) {
      // Each page scopes its own card as the lazy stack builds it. Scoping the whole collection up
      // front made a store for every card in the results, and every action anywhere in the app
      // then ran a check in each of those stores (measured at about 2.5 ms per action).
      ForEach(store.cards.ids, id: \.self) { id in
        CardPage(store: store, id: id)
      }
    }
    .scrollTargetLayout()
  }
}
