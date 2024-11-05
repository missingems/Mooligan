import ComposableArchitecture
import DesignComponents
import ScryfallKit
import SwiftUI
import Networking

struct SetsView<Client: GameSetRequestClient>: View {
  @Environment(\.colorScheme) private var colorScheme
  private var store: StoreOf<Feature<Client>>
  
  var body: some View {
    List(Array(store.sets.enumerated()), id: \.element) { (offset, element) in
      SetRow(
        viewModel: store.state.getSetRowViewModel(
          at: offset,
          colorScheme: colorScheme
        )
      ) {
        store.send(.didSelectSet(index: offset))
      }
      .id(element.id)
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

#Preview("Live Data") {
  SetsView(
    store: Store(
      initialState: Feature.State(),
      reducer: {
        Feature(client: ScryfallClient())
      }
    )
  )
}
