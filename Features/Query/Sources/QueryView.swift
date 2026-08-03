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
  private let gridItems: [GridItem]
  @Environment(\.colorScheme) var colorScheme
  @State private var cardSize: CGSize = .zero
  @FocusState private var isSearchFocused: Bool
  
  init(store: StoreOf<QueryFeature>, zoomAnimation: Namespace.ID) {
    self.store = store
    self.gridItems = [GridItem](
      repeating: GridItem(
        spacing: 3.0,
        alignment: .center
      ),
      count: Int(store.numberOfColumns)
    )
    self.zoomAnimation = zoomAnimation
  }
  
  var body: some View {
    ScrollView(.vertical) {
      if let dataSource = store.dataSource {
        LazyVGrid(columns: gridItems, spacing: 3.0) {
          CardGridContentView(
            store: store,
            dataSource: dataSource,
            cardSize: cardSize,
            zoomAnimation: zoomAnimation
          )
          .blur(radius: store.mode == .loading ? 8.0 : 0)
          .scaleEffect(store.mode == .loading ? 0.97 : 1)
          .opacity(store.mode == .loading ? 0.2 : 1)
          .placeholder(store.mode.isPlaceholder)
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
        }
      }
      .padding(.bottom, 13)
      .padding(.horizontal, systemHorizontalMargin)
      .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.isSearchExpanded)
      .animation(.default, value: store.query)
    }
    .scrollEdgeEffectStyle(.soft, for: .all)
    .contentMargins(
      .all,
      EdgeInsets(top: 0, leading: 5, bottom: 13.0, trailing: 5),
      for: .scrollContent
    )
    .onGeometryChange(for: CGFloat.self) { proxy in
      proxy.size.width
    } action: { newWidth in
      calculateCardSize(availableWidth: newWidth)
    }
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
    .overlay {
      ProgressView {
        Text("Loading...")
      }
      .opacity(store.mode == .loading ? 1 : 0)
    }
    .background(DesignComponentsAsset.backgroundColor.swiftUIColor)
    .task { store.send(.viewAppeared) }
  }
  
  private func calculateCardSize(availableWidth: CGFloat) {
    let columns = CGFloat(store.numberOfColumns)
    guard columns > 0 else { return }
    
    let horizontalPadding: CGFloat = 10.0
    let spacing: CGFloat = 3.0
    let totalSpacing = spacing * (columns - 1)
    
    let usableWidth = availableWidth - horizontalPadding - totalSpacing
    let itemWidth = max(0, usableWidth / columns)
    let itemHeight = itemWidth * MagicCardImageRatio.heightToWidth.rawValue
    
    self.cardSize = CGSize(width: itemWidth.rounded(), height: itemHeight.rounded())
  }
}
