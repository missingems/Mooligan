import ComposableArchitecture
import DesignComponents
import Foundation
import Featurist
import Networking
import SwiftUI
import NukeUI

struct QueryView: View {
  @Bindable private var store: StoreOf<QueryFeature>
  var zoomAnimation: Namespace.ID
  @Namespace private var searchMorph
  @Environment(\.colorScheme) var colorScheme
  @State private var cardSize: CGSize = .zero
  
  init(store: StoreOf<QueryFeature>, zoomAnimation: Namespace.ID) {
    self.store = store
    self.zoomAnimation = zoomAnimation
  }
  
  private var gridItems: [GridItem] {
    [GridItem](
      repeating: GridItem(spacing: 8.0, alignment: .center),
      count: max(1, Int(store.numberOfColumns))
    )
  }
  
  var body: some View {
    ScrollView(.vertical) {
      if store.dataSource != nil {
        LazyVGrid(columns: gridItems, spacing: 8.0) {
          CardGridContentView(
            store: store,
            cardSize: cardSize,
            zoomAnimation: zoomAnimation
          )
        }
        .overlay {
          if store.mode == .loading {
            LoadingGridOverlay()
          }
        }
      }
    }
    .safeAreaBar(edge: .top) {
      GlassEffectContainer {
        HStack(spacing: 8.0) {
          if !store.isSearchExpanded {
            ColorTypeItemsView(store: store)
            CardTypeItemsView(store: store)
            SortOptionsView(store: store)
          }
          
          SearchBar(
            text: $store.query.name,
            isExpanded: $store.isSearchExpanded,
            placeholder: store.searchPrompt
          )
          .glassEffectID("searchBar", in: searchMorph)
        }
      }
      .padding(.bottom, 21)
      .padding(.horizontal, systemHorizontalMargin)
      .animation(.default, value: store.isSearchExpanded)
      .animation(.default, value: store.query)
    }
    .scrollEdgeEffectStyle(.soft, for: .top)
    .contentMargins(
      .all,
      EdgeInsets(top: 0, leading: systemHorizontalMargin, bottom: 13.0, trailing: systemHorizontalMargin),
      for: .scrollContent
    )
    .scrollDisabled(store.mode.isScrollable == false)
    .scrollPosition($store.scrollPosition)
    .scrollBounceBehavior(.basedOnSize)
    .navigationTitle(store.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(id: "info", placement: .principal) {
        QueryInfoView(store: store)
      }
    }
    .background(DesignComponentsAsset.backgroundColor.swiftUIColor)
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
