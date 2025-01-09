import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking

struct SetsView: View {
  private var store: StoreOf<Feature>
  
  var body: some View {
    List(Array(zip(store.sets, store.sets.indices)), id: \.0.id) { value in
      let set = value.0
      let index = value.1
      
      SetRow(
        viewModel: SetRow.ViewModel(
          set: set,
          selectedSet: nil,
          index: index
        )
      ) {
        store.send(.didSelectSet(set))
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
