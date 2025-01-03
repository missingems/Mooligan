import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking

struct SetsView: View {
  private var store: StoreOf<Feature>
  
  var body: some View {
    List(Array(zip(store.sets, store.sets.indices)), id: \.0) { value in
      let card = value.0
      let index = value.1
      
      SetRow(
        viewModel: SetRow.ViewModel(
          set: card,
          selectedSet: nil,
          index: index
        )
      ) {
        store.send(.didSelectSet(card))
      }
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
      .safeAreaPadding(.horizontal, nil)
    }
    .listStyle(.plain)
    .task {
      store.send(.viewAppeared)
    }
  }
  
  init(store: StoreOf<Feature>) {
    self.store = store
  }
}
