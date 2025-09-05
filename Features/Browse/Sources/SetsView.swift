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
            
            var hasSeparator: Bool {
              if isFirstOfSection, isLastOfSection {
                return false
              }
              
              if isFirstOfSection, set.parentSetCode == nil {
                return false
              }
              
              if set.parentSetCode == nil {
                return false
              } else {
                return true
              }
            }
            
            var insets: EdgeInsets {
              if isFirstOfSection, isLastOfSection {
                return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
              }
              
              if isFirstOfSection, set.parentSetCode == nil {
                return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
              }
              
              if set.parentSetCode == nil {
                return EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
              } else {
                return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
              }
            }
            
            ZStack(alignment: .top) {
              SetRow(
                viewModel: Self.viewModel(
                  sets: value.sets,
                  highlightedText: store.query,
                  index: index
                )
              ) {
                store.send(.didSelectSet(set))
              }
              .shimmering(active: store.mode.isPlaceholder)
              
              if hasSeparator {
                Divider().padding(.leading, 60.0)
              }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color(uiColor: .clear))
            .listRowInsets(insets)
            .safeAreaPadding(.horizontal, nil)
          }
        } header: {
          Text(value.displayDate)
        }
      }
      .listStyle(.plain)
      .listSectionSeparator(.hidden)
      .redacted(reason: store.mode.isPlaceholder ? .placeholder : [])
      .scrollDisabled(store.mode.isPlaceholder)
      .allowsHitTesting(store.mode.isPlaceholder == false)
      .background(Color(.systemGroupedBackground))
      .refreshable {
        await store.send(.searchSets(.all)).finish()
      }
      .contentMargins(.bottom, 13, for: .scrollContent)
      .searchable(
        text: Binding(get: {
          store.query
        }, set: { newValue in
          if store.query != newValue {
            store.query = newValue
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
