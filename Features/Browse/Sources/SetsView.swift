import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking

struct SetsView<Client: GameSetRequestClient>: View {
  @Environment(\.colorScheme) private var colorScheme
  private var store: StoreOf<Feature<Client>>
  
  var body: some View {
    List(store.sets.indices, id: \.self) { index in
      let element = store.sets[index]
      
      SetRow(
        viewModel: store.state.getSetRowViewModel(
          at: index,
          colorScheme: colorScheme
        )
      ) {
        store.send(.didSelectSet(index: index))
      }
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 0))
      .safeAreaPadding(.horizontal, nil)
    }
    .listStyle(.plain)
    .task {
      store.send(.viewAppeared)
    }
  }
  
  init(store: StoreOf<Feature<Client>>) {
    self.store = store
  }
}
