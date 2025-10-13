import ComposableArchitecture
import DesignComponents
import Foundation
import Featurist
import Networking
import SwiftUI
import NukeUI

struct QueryView: View {
  @Bindable private var store: StoreOf<QueryFeature>
  private let gridItems: [GridItem]
  
  init(store: StoreOf<QueryFeature>) {
    self.store = store
    gridItems = [GridItem](
      repeating: GridItem(
        spacing: 5,
        alignment: .center
      ),
      count: Int(store.numberOfColumns)
    )
  }
  
  var body: some View {
    ScrollView(.vertical) {
      LazyVGrid(columns: gridItems, spacing: 5) {
        if let dataSource = store.dataSource {
          contentScrollView(dataSource: dataSource)
        }
//        if let contentWidth = store.itemWidth, contentWidth > 0, let dataSource = store.dataSource {
          
//            .blur(radius: store.mode == .loading ? 8.0 : 0)
//            .scaleEffect(store.mode == .loading ? 0.97 : 1)
//            .opacity(store.mode == .loading ? 0.2 : 1)
//        }
      }
      .padding(.horizontal, 5.0)
//      .padding(.horizontal, 0)
//      .onGeometryChange(for: CGFloat.self, of: { proxy in proxy.size.width }) { newValue in
//        guard store.viewWidth == nil, newValue > 0 else {
//          return
//        }
//        
//        store.viewWidth = newValue
//      }
//      .placeholder(store.mode.isPlaceholder)
    }
    .background { Color(.systemGroupedBackground).ignoresSafeArea() }
//    .searchable(text: $store.query.name, placement: .navigationBarDrawer(displayMode: .always))
    .contentMargins(.vertical, EdgeInsets(top: 3.0, leading: 0, bottom: 13.0, trailing: 0), for: .scrollContent)
    .scrollDisabled(store.mode.isScrollable == false)
    .scrollPosition($store.scrollPosition)
    .scrollBounceBehavior(.basedOnSize)
    .navigationTitle(store.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { toolbar }
    .overlay {
      ProgressView {
        Text("Loading...")
      }
      .opacity(store.mode == .loading ? 1 : 0)
    }
    .task { store.send(.viewAppeared) }
  }
  
  @ViewBuilder private func contentScrollView(dataSource: CardDataSource) -> some View {
    ForEach(Array(zip(dataSource.cardDetails, dataSource.cardDetails.indices)), id: \.0.card.id) { value in
      let cardInfo = value.0
      let index = value.1
      
      Button {
        store.send(.didSelectCard(cardInfo.card, store.queryType))
      } label: {
        CardView(
          displayableCard: cardInfo.displayableCardImage!,
          callToActionHorizontalOffset: 5.0,
          priceVisibility: .hidden
        )
      }
      .disabled(store.mode.isScrollable == false)
      .buttonStyle(.sinkableButtonStyle)
      .task {
        if store.state.shouldLoadMore(at: index) {
          store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
        }
      }
    }
  }
  
  @ToolbarContentBuilder private var toolbar: some ToolbarContent {
    ToolbarItem(id: "info", placement: .principal) {
      infoView(query: store.queryType)
    }
    
    ToolbarItem(id: "sort", placement: .topBarTrailing) {
      sortView
    }
  }
  
  @ViewBuilder private var sortView: some View {
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
      ZStack {
        ProgressView()
          .opacity((store.mode == .loading || store.mode == .placeholder) ? 1 : 0)
        
        Image(systemName: "ellipsis")
          .opacity((store.mode == .loading || store.mode == .placeholder) ? 0 : 1)
      }
    }
    .pickerStyle(.inline)
    .labelsVisibility(.visible)
    .disabled(store.mode == .loading || store.mode == .placeholder)
  }
  
  @ViewBuilder private func infoView(query: QueryType) -> some View {
    Button {
      store.send(.didSelectShowInfo)
    } label: {
      switch store.queryType {
      case .querySet:
        Text(store.title).multilineTextAlignment(.center).font(.subheadline).fontWeight(.semibold).lineLimit(1)
        .frame(minHeight: 44.0, alignment: .center)
        .padding(.horizontal, 13.0)
        .glassEffect()
        
      case .search:
        Text("")
      }
    }
    .buttonStyle(.plain)
    .popover(isPresented: $store.isShowingInfo, attachmentAnchor: .rect(.bounds)) {
      VStack(spacing: 0) {
        ForEach(Array(zip(store.queryType.sections, store.queryType.sections.indices)), id: \.0.id) { section in
          VStack(spacing: 0) {
            section.0.body
              .padding(.vertical, 11.0)
              .safeAreaPadding(.horizontal, nil)
            
            if section.1 != store.queryType.sections.count - 1 {
              Divider().safeAreaPadding(.leading, nil)
            }
          }
        }
      }
      .padding(.vertical, 11)
      .presentationCompactAdaptation(.popover)
    }
  }
}

private extension QueryType.Section {
  var body: some View {
    Group {
      switch self {
      case .titleDetail(let title, let detail):
        HStack {
          Text(title)
          Spacer(minLength: 55)
          Text(detail ?? "").foregroundStyle(.secondary)
        }
        
      case .titleIcon(let title, let iconURL):
        HStack {
          Text(title)
          Spacer(minLength: 55)
          IconLazyImage(
            iconURL,
            tintColor: .secondary
          )
          .frame(width: 21, height: 21, alignment: .center)
        }
        
      case .titleCode(let title, let code):
        HStack {
          Text(title)
          Spacer(minLength: 55)
          Text(code.uppercased()).foregroundStyle(.secondary).fontDesign(.monospaced)
        }
      }
    }
  }
}
