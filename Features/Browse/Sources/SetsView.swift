import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking

struct SetsView: View {
  @Bindable private var store: StoreOf<BrowseFeature>
  
  var body: some View {
    List(store.sections) { value in
      Section(content: {
        ForEach(Array(zip(value.sets, value.sets.indices)), id: \.0.id) { value in
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
        }
      }, header: {
        Text(
          value.date.formatted(
            date: .abbreviated,
            time: .omitted
          )
        )
        .padding(.vertical, 8.0)
      })
      .listSectionSpacing(13.0)
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
      placement: .automatic,
      prompt: store.queryPlaceholder
    )
    .listStyle(.plain)
    .listSectionSeparator(.hidden)
    .task {
      store.send(.viewAppeared)
    }
  }
  
  init(store: StoreOf<BrowseFeature>) {
    self.store = store
  }
}
