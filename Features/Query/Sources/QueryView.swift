import ComposableArchitecture
import DesignComponents
import Foundation
import Featurist
import Networking
import Shimmer
import SwiftUI
import NukeUI

struct QueryView: View {
  @Bindable private var store: StoreOf<Feature>
  private let gridItems: [GridItem]
  
  init(store: StoreOf<Feature>) {
    self.store = store
    gridItems = [GridItem](
      repeating: GridItem(
        spacing: 8.0,
        alignment: .center
      ),
      count: Int(store.numberOfColumns)
    )
  }
  
  var body: some View {
    ScrollView(.vertical) {
      LazyVGrid(columns: gridItems, spacing: 13) {
        if let contentWidth = store.itemWidth, contentWidth > 0, let dataSource = store.dataSource {
          contentScrollView(dataSource: dataSource, contentWidth: contentWidth)
        }
      }
      .onGeometryChange(
        for: CGFloat.self,
        of: { proxy in
          proxy.size.width
        }, action: { newValue in
          guard store.viewWidth == nil, newValue > 0 else {
            return
          }
          
          store.viewWidth = newValue
        }
      )
      .safeAreaPadding(.horizontal, nil)
      .placeholder(store.mode.isPlaceholder)
    }
    .contentMargins(.vertical, 8, for: .scrollContent)
    .scrollDisabled(store.mode.isPlaceholder)
    .scrollPosition($store.scrollPosition)
    .scrollBounceBehavior(.basedOnSize)
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(store.title)
    .toolbar { toolbar }
    .task { store.send(.viewAppeared) }
  }
  
  @ViewBuilder private func contentScrollView(dataSource: QueryDataSource, contentWidth: CGFloat) -> some View {
    ForEach(Array(zip(dataSource.cardDetails, dataSource.cardDetails.indices)), id: \.0.card.id) { value in
      let cardInfo = value.0
      let index = value.1
      
      let layout = CardView.LayoutConfiguration(
        rotation: .portrait,
        maxWidth: contentWidth
      )
      
      Button {
        store.send(.didSelectCard(cardInfo.card, store.queryType))
      } label: {
        CardView(
          displayableCard: cardInfo.displayableCardImage,
          layoutConfiguration: layout,
          callToActionHorizontalOffset: 5.0,
          priceVisibility: .display(
            usdFoil: cardInfo.card.getPrice(for: .usdFoil),
            usd: cardInfo.card.getPrice(for: .usd)
          )
        )
      }
      .buttonStyle(.sinkableButtonStyle)
      .task {
        if store.state.shouldLoadMore(at: index) {
          store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
        }
      }
    }
  }
  
  @ToolbarContentBuilder private var toolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .primaryAction) {
      if case .querySet = store.queryType {
        Menu {
          Picker("SORT BY", selection: $store.query.sortMode) {
            ForEach(store.availableSortModes) { value in
              Text(value.description)
            }
          }
          
          Picker("SORT ORDER", selection: $store.query.sortDirection) {
            ForEach(store.availableSortOrders) { value in
              Text(value.description)
            }
          }
        } label: {
          Image(systemName: "arrow.up.arrow.down.circle.fill")
            .font(.title3)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
              DesignComponentsAsset.accentColor.swiftUIColor,
              Color(.tertiarySystemFill)
            )
        }
        .pickerStyle(.inline)
        .labelsVisibility(.visible)
        
        Button("Filter", systemImage: "line.3.horizontal.decrease.circle.fill") {
          store.send(.didSelectShowFilters)
        }
        .buttonStyle(HierarchicalToolbarButton())
        .popover(
          isPresented: $store.isShowingSortFilters,
          content: { filterView }
        )
      }
    }
  }
  
  @ViewBuilder private var filterView: some View {
    NavigationStack {
      List {
        TextField("Enter card name", text: $store.query.name)
        
        Picker("SORT BY", selection: $store.query.sortMode) {
          ForEach(store.availableSortModes) { value in
            Text(value.description)
          }
        }
        .pickerStyle(.inline)
        .labelsVisibility(.visible)
        
        Picker("SORT ORDER", selection: $store.query.sortDirection) {
          ForEach(store.availableSortOrders) { value in
            Text(value.description)
          }
        }
        .pickerStyle(.inline)
        .labelsVisibility(.visible)
      }
      .navigationTitle("Filter")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
          } label: {
            Text("Done")
          }
        }
      }
    }
  }
}
