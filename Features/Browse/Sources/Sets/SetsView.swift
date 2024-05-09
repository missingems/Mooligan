import ComposableArchitecture
import DesignComponents
import ScryfallKit
import SwiftUI
import Networking

struct SetsView<Client: GameSetRequestClient>: View {
  @Environment(\.colorScheme) private var colorScheme
  private var store: StoreOf<Feature<Client>>
  
  var body: some View {
    List(store.sets.indices, id: \.self) { index in
      SetRow(
        viewModel: store.state.getSetRowViewModel(
          at: index,
          colorScheme: colorScheme
        )
      ) {
        store.send(.didSelectSet(index: index))
      }
      .buttonStyle(.sinkableButtonStyle)
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 0))
      .safeAreaPadding(.horizontal, nil)
    }
    .listStyle(.plain)
    .onAppear {
      store.send(.viewAppeared)
    }
  }
  
  init(store: StoreOf<Feature<Client>>) {
    self.store = store
    
#if DEBUG
    DesignComponents.Main().setup()
#endif
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
