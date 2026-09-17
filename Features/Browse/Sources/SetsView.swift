import ComposableArchitecture
import DesignComponents
import SwiftUI
import Networking
import ScryfallKit

struct SetsView: View {
  @Bindable private var store: StoreOf<BrowseFeature>

  var body: some View {
    Group {
      switch store.mode {
      case let .data(sections):
        setList(sections: sections, rows: store.rows, highlightedText: store.query)
        
      case .loading:
        ProgressView()
          .controlSize(.large)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(DesignComponentsAsset.backgroundColor.swiftUIColor.ignoresSafeArea())
        
      case let .error(message):
        ContentUnavailableView {
          Label("Failed to load", systemImage: "wifi.slash")
        } description: {
          Text(message)
        } actions: {
          Button {
            let _ = withAnimation {
              store.send(.retry)
            }
          } label: {
            Text("Retry")
              .font(.body)
              .fontWeight(.semibold)
              .padding(.horizontal, 13.0)
              .padding(.vertical, 5.0)
              .glassEffect()
              .padding(.bottom, 3.0)
          }
        }
        .background(DesignComponentsAsset.backgroundColor.swiftUIColor.ignoresSafeArea())
      }
    }
    .task {
      store.send(.viewAppeared)
    }
  }
   
  @ContentBuilder
  private func setList(
    sections: IdentifiedArrayOf<ScryfallClient.SetsSection>,
    rows: [ScryfallClient.SetsSection.ID: [SetRow.ViewModel]],
    highlightedText: String
  ) -> some View {
    ScrollView(.vertical) {
      LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
        ForEach(sections) { value in
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
              
              var topInset: CGFloat {
                if isFirstOfSection { return 0 }
                return set.parentSetCode == nil ? 8 : 0
              }
              
              if let row = rows[value.id]?[safe: index] {
                ZStack(alignment: .top) {
                  SetRow(viewModel: row, highlightedText: highlightedText) {
                    store.send(.didSelectSet(set))
                  }
                  .equatable()

                  if hasSeparator {
                    VibrantDivider().padding(.leading, 60.0)
                  }
                }
                .padding(.top, topInset)
                .padding(.horizontal, systemHorizontalMargin)
              }
            }
          } header: {
            HStack(spacing: 5.0) {
              if value.isUpcomingSet {
                Image(systemName: "hourglass")
              }
              Text(value.displayDate)
            }
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 13.0)
            .padding(.vertical, 5.0)
            .glassEffect()
            .padding(EdgeInsets(top: 10.0, leading: systemHorizontalMargin, bottom: 13.0, trailing: systemHorizontalMargin))
          } footer: {
            Color.clear.frame(height: 13.0)
          }
        }
      }
    }
    .accessibilityIdentifier("browse.setList")
    .scrollEdgeEffectStyle(.soft, for: .all)
    .background(DesignComponentsAsset.backgroundColor.swiftUIColor.ignoresSafeArea())
    .contentMargins(.top, 0, for: .scrollContent)
    .refreshable {
      await store.send(.refresh).finish()
    }
  }
  
  init(store: StoreOf<BrowseFeature>) {
    self.store = store
  }
}
