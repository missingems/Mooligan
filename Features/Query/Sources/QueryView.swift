import ComposableArchitecture
import DesignComponents
import Foundation
import Featurist
import Networking
import SwiftUI
import NukeUI

struct QueryView: View {
  @Bindable private var store: StoreOf<QueryFeature>
  @Namespace private var searchMorph
  @Environment(\.colorScheme) var colorScheme
  @State private var cardLayoutConfig: CardView.LayoutConfiguration?
  @State private var topBarAvailableWidth: CGFloat? = nil
  
  init(store: StoreOf<QueryFeature>) {
    self.store = store
  }
  
  private var gridItems: [GridItem] {
    [GridItem](
      repeating: GridItem(spacing: 8.0, alignment: .center),
      count: max(1, Int(store.numberOfColumns))
    )
  }
  
  var body: some View {
    ScrollView(.vertical) {
      LazyVGrid(columns: gridItems, spacing: 8.0) {
        if let cardLayoutConfig {
          CardGridContentView(
            store: store,
            layoutConfiguration: cardLayoutConfig
          )
        }
      }
    }
    .onGeometryChange(
      for: CGFloat.self,
      of: { proxy in proxy.size.width },
      action: { width in
        topBarAvailableWidth = width - (systemHorizontalMargin * 2)
        
        let columns = CGFloat(max(1, store.numberOfColumns))
        let totalSpacing = 8.0 * (columns - 1)
        
        let availableWidth = width - (systemHorizontalMargin * 2) - totalSpacing
        let columnWidth = (availableWidth / columns).rounded(.down)
        
        if columnWidth > 0, cardLayoutConfig?.size.width != columnWidth {
          cardLayoutConfig = CardView.LayoutConfiguration(rotation: .portrait, maxWidth: columnWidth)
        }
      }
    )
    .safeAreaBar(edge: .top) {
      if store.mode.isPlaceholder == false {
        GlassEffectContainer {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8.0) {
              if !store.isSearchExpanded {
                ColorTypeItemsView(store: store)
                CardTypeItemsView(store: store)
                SortOptionsView(store: store)
              }
              
              SearchBar(
                text: $store.query.name,
                isExpanded: $store.isSearchExpanded,
                isLoading: store.mode.isLoading,
                placeholder: store.searchPrompt
              )
              .glassEffectID("searchBar", in: searchMorph)
            }
            .frame(minWidth: topBarAvailableWidth)
          }
        }
        .animation(.default, value: store.isSearchExpanded)
        .animation(.default, value: store.query)
      }
    }
    .scrollEdgeEffectStyle(.soft, for: .top)
    .contentMargins(
      .all,
      EdgeInsets(top: 0, leading: systemHorizontalMargin, bottom: 13.0, trailing: systemHorizontalMargin),
      for: .scrollContent
    )
    .scrollDisabled(store.mode.isScrollable == false)
    .scrollPosition(.init(get: {
      store.scrollPosition
    }, set:  { _ in }))
    .scrollBounceBehavior(.basedOnSize)
    .navigationTitle(store.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(id: "info", placement: .principal) {
        QueryInfoView(store: store)
      }
    }
    .background(
      DesignComponentsAsset.backgroundColor.swiftUIColor.ignoresSafeArea()
    )
    .overlay {
      if store.mode.isPlaceholder {
        ProgressView().controlSize(.large)
      }
    }
    .animation(.smooth, value: store.mode.isPlaceholder)
    .task { store.send(.viewAppeared) }
  }
}

private struct LoadingGridOverlay: View {
  var body: some View {
    ProgressView {
      Text("Loading...")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.ultraThinMaterial)
    .transition(.opacity)
  }
}
