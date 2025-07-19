import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking
import ScryfallKit

struct SetsView: View {
  @Bindable private var store: StoreOf<BrowseFeature>
  
  static func viewModel(
    sets: [MTGSet],
    highlightedText: String?,
    index: Int
  ) -> SetRow.ViewModel {
    let set = sets[index]
    let nextIndex = index + 1
    let isLast: Bool
    
    if let nextSet = sets[safe: nextIndex] {
      if nextSet.parentSetCode == nil {
        isLast = true
      } else {
        isLast = false
      }
    } else {
      isLast = true
    }
    
    return SetRow.ViewModel(
      set: set,
      selectedSet: nil,
      highlightedText: highlightedText,
      isLast: isLast,
      index: index
    )
  }
  
  var body: some View {
    switch store.mode {
    case let .data(sections), let .placeholder(sections):
      List(sections) { value in
        Section {
          ForEach(
            Array(zip(value.sets, value.sets.indices)),
            id: \.0.id
          ) { innerValue in
            let set = innerValue.0
            let index = innerValue.1
            let isFirstOfSection = index == 0
            let isLastOfSection = index == value.sets.count - 1
            
            var insets: EdgeInsets {
              if isFirstOfSection, isLastOfSection {
                return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
              }
              
              if isFirstOfSection, set.parentSetCode == nil {
                return EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0)
              }
              
              if set.parentSetCode == nil {
                return EdgeInsets(top: 8, leading: 0, bottom: 1, trailing: 0)
              } else {
                return EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0)
              }
            }
            
            let viewModel = Self.viewModel(
              sets: value.sets,
              highlightedText: store.query,
              index: index
            )
            
            SetRow(viewModel: viewModel) {
              store.send(.didSelectSet(set))
            }
            .listSectionSpacing(13.0)
            .listRowSeparator(.hidden)
            .listRowInsets(insets)
            .safeAreaPadding(.horizontal, nil)
          }
        } header: {
          Text(value.displayDate)
        }
      }
      .listStyle(.plain)
      .listSectionSeparator(.hidden)
      .searchable(
        text: Binding(get: {
          store.query
        }, set: { value in
          if store.query != value {
            store.query = value
          }
        }),
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: store.queryPlaceholder
      )
      .task {
        store.send(.viewAppeared)
      }
    }
  }
  
  init(store: StoreOf<BrowseFeature>) {
    self.store = store
  }
}
