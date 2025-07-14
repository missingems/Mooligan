import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking

struct SetsView: View {
  @Bindable private var store: StoreOf<BrowseFeature>
  
  var body: some View {
    List(Array(zip(store.sets, store.sets.indices)), id: \.0.id) { value in
      let set = value.0
      let index = value.1
      
      SetRow(
        viewModel: SetRow.ViewModel(
          set: set,
          selectedSet: nil,
          highlightedText: store.query,
          index: index
        )
      ) {
        store.send(.didSelectSet(set))
      }
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
      .safeAreaPadding(.horizontal, nil)
    }
    .searchable(
      text: .init(get: {
        store.query
      }, set: { value in
        if store.query != value {
          store.query = value
        }
      }),
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: store.queryPlaceholder
    )
    .listStyle(.plain)
    .task {
      store.send(.viewAppeared)
    }
  }
  
  init(store: StoreOf<BrowseFeature>) {
    self.store = store
  }
}
