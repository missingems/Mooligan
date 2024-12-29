import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking

struct SetsView: View {
  private var store: StoreOf<Feature>
  
  var body: some View {
    List(Array(zip(store.sets, store.sets.indices)), id: \.0) { value in
      SetRow(
        viewModel: SetRow.ViewModel(
          set: value.0,
          selectedSet: nil,
          index: value.1
        )
      ) {
        store.send(.didSelectSet(index: value.1))
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
