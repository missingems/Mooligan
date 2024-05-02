import ComposableArchitecture
import DesignComponents
import ScryfallKit
import SwiftUI
import Networking

struct SetsView<Client: BrowseRequestClient>: View {
  @Environment(\.colorScheme)
  private var colorScheme
  
  private var store: StoreOf<Feature<Client>>
  
  init(store: StoreOf<Feature<Client>>) {
    self.store = store
  }
  
  var body: some View {
    List(store.sets.indices, id: \.self) { index in
      let data = store.sets[index]
      
      Button(
        action: { 
          store.send(.didSelectSet(data))
        },
        label: {
          SetRow(
            viewModel: SetRow.ViewModel(
              iconURL: data.iconURL,
              id: data.code,
              colorScheme: colorScheme,
              isHighlighted: false,
              index: index,
              numberOfCards: data.numberOfCards,
              shouldShowIndentIndicator: data.isParent == false,
              title: data.name
            )
          )
        }
      )
      .buttonStyle(.sinkableButtonStyle)
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets())
    }
    .listStyle(.plain)
    .onAppear {
      store.send(.viewAppeared)
    }
  }
}
