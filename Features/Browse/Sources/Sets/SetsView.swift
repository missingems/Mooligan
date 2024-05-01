import ComposableArchitecture
import ScryfallKit
import SwiftUI
import Networking

struct SetsView<Client: BrowseRequestClient>: View {
  private var store: StoreOf<Feature<Client>>
  
  init(store: StoreOf<Feature<Client>>) {
    self.store = store
  }
  
  var body: some View {
    List(store.sets.indices, id: \.self) { index in
      let data = store.sets[index]
      
      SetRow(
        viewModel: SetRow.ViewModel(
          iconURL: data.iconURL,
          id: data.code,
          isDarkMode: false,
          isHighlighted: false,
          index: index,
          numberOfCards: data.numberOfCards,
          shouldShowIndentIndicator: false,
          title: data.name
        )
      )
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets())
    }
    .listStyle(.plain)
    .onAppear {
      store.send(.viewAppeared)
    }
  }
}
