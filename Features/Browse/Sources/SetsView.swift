import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking

struct SetsView: View {
  private var store: StoreOf<BrowseFeature>
  private let namespace: Namespace.ID
  
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
      .matchedTransitionSource(id: set.id, in: namespace)
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
      .safeAreaPadding(.horizontal, nil)
    }
    .listStyle(.plain)
    .task {
      store.send(.viewAppeared)
    }
  }
  
  init(store: StoreOf<BrowseFeature>, namespace: Namespace.ID) {
    self.store = store
    self.namespace = namespace
  }
}
