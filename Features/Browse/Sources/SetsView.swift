import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking
import ScryfallKit

struct SetsView: View {
  @Bindable private var store: StoreOf<BrowseFeature>
  
  static func viewModel(
    sets: [MTGSet],
    selectedSet: MTGSet?,
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
      selectedSet: selectedSet,
      highlightedText: highlightedText,
      isFirst: set.parentSetCode == nil || sets[safe: index - 1] == nil,
      isLast: isLast,
      index: index
    )
  }
  
  var body: some View {
    Group {
      switch store.mode {
      case let .data(sections):
        setList(sections: sections, isPlaceholder: false, isScrollable: true)
        
      case let .placeholder(sections):
        setList(sections: sections, isPlaceholder: true, isScrollable: false)
        
      case let .error(message):
        ZStack {
          setList(
            sections: IdentifiedArrayOf(uniqueElements: MockGameSetRequestClient.mocksSetSections),
            isPlaceholder: true,
            isScrollable: false
          )
          .blur(radius: 12.0)
          
          ContentUnavailableView {
            Label("Failed to load", systemImage: "exclamationmark.triangle.fill")
          } description: {
            Text(message)
          } actions: {
            Button {
              store.send(.retry)
            } label: {
              Text("Retry")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(DesignComponentsAsset.invertedPrimary.swiftUIColor)
                .frame(maxWidth: .infinity, minHeight: 34)
                .padding(.vertical, 5.0)
                .padding(.horizontal, 13.0)
                .background(DesignComponentsAsset.accentColor.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(
                  RoundedRectangle(cornerRadius: 13)
                )
            }
            .buttonStyle(.sinkableButtonStyle)
          }
          .background(.ultraThinMaterial)
        }
      }
    }
    .task {
      store.send(.viewAppeared)
    }
  }
  
  @ViewBuilder
  private func setList(
    sections: IdentifiedArrayOf<ScryfallClient.SetsSection>,
    isPlaceholder: Bool,
    isScrollable: Bool
  ) -> some View {
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
            if isFirstOfSection, isLastOfSection { return false }
            if isFirstOfSection, set.parentSetCode == nil { return false }
            if set.parentSetCode == nil { return false }
            else { return true }
          }
          
          var insets: EdgeInsets {
            if isFirstOfSection, isLastOfSection { return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0) }
            if isFirstOfSection, set.parentSetCode == nil { return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0) }
            if set.parentSetCode == nil { return EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0) }
            else { return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0) }
          }
          
          ZStack(alignment: .top) {
            SetRow(
              viewModel: Self.viewModel(
                sets: value.sets,
                selectedSet: store.selectedSet,
                highlightedText: store.query,
                index: index
              )
            ) {
              store.send(.didSelectSet(set))
            }
            .shimmering(active: isPlaceholder)
            
            if hasSeparator {
              Divider().padding(.leading, 60.0)
            }
          }
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .listRowVerticalInsets(top: insets.top, bottom: insets.bottom)
        }
      } header: {
        Text(value.displayDate)
          .padding(.horizontal, 13.0)
          .padding(.vertical, 5.0)
          .glassEffect()
          .padding(.bottom, 3.0)
      }
    }
    .scrollEdgeEffectStyle(.soft, for: .all)
    .listStyle(.plain)
    .listSectionSeparator(.hidden)
    .conditionalModifier(isScrollable, transform: { view in
      view.searchable(text: $store.query)
    })
    .background { Color(.systemGroupedBackground).ignoresSafeArea() }
    .redacted(reason: isPlaceholder ? .placeholder : [])
    .scrollDisabled(isPlaceholder)
    .allowsHitTesting(isPlaceholder == false)
    .contentMargins(.top, 0, for: .scrollContent)
    .listSectionSpacing(13.0)
    .refreshable {
      await store.send(.searchSets(.all)).finish()
    }
  }
  
  init(store: StoreOf<BrowseFeature>) {
    self.store = store
  }
}
