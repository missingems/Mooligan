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
        spacing: 5.0,
        alignment: .center
      ),
      count: Int(store.numberOfColumns)
    )
  }
  
  var body: some View {
    ScrollView(.vertical) {
      if let dataSource = store.dataSource {
        LazyVGrid(columns: gridItems, spacing: 5.0) {
          Section {
            contentScrollView(dataSource: dataSource)
              .blur(radius: store.mode == .loading ? 8.0 : 0)
              .scaleEffect(store.mode == .loading ? 0.97 : 1)
              .opacity(store.mode == .loading ? 0.2 : 1)
              .placeholder(store.mode.isPlaceholder)
          } header: {
            HStack(spacing: 5.0) {
              colorTypeItems
              typesMenuItems
              sortView
            }
            .animation(.default, value: store.query)
            .padding(.bottom, 5.0)
          }
        }
      }
    }
    .contentMargins(
      .all,
      EdgeInsets(top: 0, leading: 8, bottom: 13.0, trailing: 8),
      for: .scrollContent
    )
    .scrollDisabled(store.mode.isScrollable == false)
    .scrollPosition($store.scrollPosition)
    .scrollBounceBehavior(.basedOnSize)
    .navigationTitle(store.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(id: "info", placement: .principal) {
        infoView(query: store.queryType)
      }
    }
    .searchable(text: $store.query.name, placement: .toolbar)
    .searchToolbarBehavior(.minimize)
    .overlay {
      ProgressView {
        Text("Loading...")
      }
      .opacity(store.mode == .loading ? 1 : 0)
    }
    .background(Color(.systemGroupedBackground))
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
          displayableCard: cardInfo.displayableCardImage,
          layoutConfiguration: nil,
          callToActionHorizontalOffset: -3.0,
          priceVisibility: .display(usdFoil: cardInfo.card.getPrice(for: .usdFoil), usd: cardInfo.card.getPrice(for: .usd)),
          shouldShowShadow: false,
          send: nil
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
  
  @ViewBuilder private var colorTypeItems: some View {
    Button {
      store.isShowingColorTypeOptions.toggle()
    } label: {
      HStack(spacing: -3) {
        ForEach(
          store.query.colorIdentities.isEmpty ? store.availableColorTypeOptions : Array(store.query.colorIdentities).sorted(),
          id: \.rawValue
        ) { value in
          value.image.resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 19, height: 21)
            .offset(x: 0, y: -0.5)
            .background { Circle().fill(.black).offset(x: -0.75, y: 1) }
        }
      }
      .frame(maxWidth: .infinity)
      .padding(
        EdgeInsets(
          top: 8,
          leading: 8,
          bottom: 8,
          trailing: 8
        )
      )
      .background(RoundedRectangle(cornerRadius: 13.0).fill(Color(.systemFill)))
    }
    .popover(
      isPresented: $store.isShowingColorTypeOptions,
      attachmentAnchor: .rect(.bounds),
      arrowEdge: .top
    ) {
      VStack(alignment: .leading, spacing: 2.0) {
        ForEach(store.availableColorTypeOptions, id: \.rawValue) { value in
          Button {
            store.query.colorIdentities.toggleSelection(for: value)
          } label: {
            HStack {
              value.image.resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 19, height: 21)
                .offset(x: 0, y: -0.5)
                .background {
                  Circle().fill(.black).offset(x: -0.75, y: 1)
                }
              
              Text(value.name)
              
              Spacer(minLength: 34)
              
              Image(systemName: "checkmark.circle.fill")
                .opacity(store.query.colorIdentities.contains(value) ? 1 : 0)
            }
            .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
            .background(
              store.query.colorIdentities.contains(value) ? Color(.systemFill) : .clear,
              in: .capsule
            )
          }
        }
      }
      .padding(EdgeInsets(top: 11.0, leading: 8.0, bottom: 11.0, trailing: 8.0))
      .presentationCompactAdaptation(.popover)
    }
  }
  
  @ViewBuilder private var typesMenuItems: some View {
    Button {
      store.isShowingCardTypeOptions.toggle()
    } label: {
      HStack(spacing: 2) {
        ForEach(
          Array(store.query.cardType).sorted(),
          id: \.rawValue
        ) { value in
          value.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(
              width: 18,
              height: 21,
              alignment: .center
            )
        }
        
        if store.query.cardType.count == 1, let value = store.query.cardType.first {
          Text(value.title)
            .font(.subheadline)
            .fontWeight(.medium)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .padding(.leading, 3)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(
        EdgeInsets(
          top: 8,
          leading: 8,
          bottom: 8,
          trailing: 8
        )
      )
      .background(Color(.systemFill))
      .clipShape(RoundedRectangle(cornerRadius: 13.0))
    }
    .popover(
      isPresented: $store.isShowingCardTypeOptions,
      attachmentAnchor: .rect(.bounds),
      arrowEdge: .top
    ) {
      VStack(alignment: .leading, spacing: 2.0) {
        ForEach(store.availableCardType) { value in
          Button {
            store.query.cardType.toggleSelection(for: value)
          } label: {
            HStack {
              Group {
                value.image
                  .renderingMode(.template)
                  .resizable()
                  .scaledToFit()
                  .frame(width: value == .all ? 15.0 : 21.0, height: 21, alignment: .center)
              }
              .frame(width: 21.0, height: 21, alignment: .center)
              
              Text(value.title)
              
              Spacer(minLength: 34)
              
              Image(systemName: "checkmark.circle.fill")
                .opacity(store.query.cardType.contains(value) ? 1 : 0)
            }
            .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
            .background(
              store.query.cardType.contains(value) ? Color(.systemFill) : .clear,
              in: .capsule
            )
          }
        }
      }
      .padding(EdgeInsets(top: 11.0, leading: 8.0, bottom: 11.0, trailing: 8.0))
      .presentationCompactAdaptation(.popover)
    }
  }
  
  @ViewBuilder private var sortView: some View {
    Button {
      store.isShowingSortOptions.toggle()
    } label: {
      HStack(spacing: 5.0) {
        Group {
          switch store.query.sortDirection {
          case .asc:
            Image(systemName: "arrow.up").resizable().scaledToFit()
          case .desc:
            Image(systemName: "arrow.down").resizable().scaledToFit()
          default:
            Image(systemName: "wand.and.sparkles").resizable().scaledToFit()
          }
        }
        .frame(width: 15, height: 21, alignment: .center)
        
        Text(store.query.sortMode.description)
          .font(.subheadline)
          .fontWeight(.medium)
          .multilineTextAlignment(.leading)
      }
      .frame(maxWidth: .infinity)
      .padding(
        EdgeInsets(
          top: 8,
          leading: 0,
          bottom: 8,
          trailing: 0
        )
      )
      .background(Color(.systemFill))
      .clipShape(RoundedRectangle(cornerRadius: 13.0))
    }
    .popover(
      isPresented: $store.isShowingSortOptions,
      attachmentAnchor: .rect(.bounds),
      arrowEdge: .top
    ) {
      VStack(alignment: .leading, spacing: 2.0) {
        ForEach(store.availableSortModes, id: \.rawValue) { value in
          Button {
            store.query.sortMode = value
          } label: {
            HStack {
              Text(value.description)
              
              Spacer(minLength: 34)
              
              Image(systemName: "checkmark.circle.fill")
                .opacity(store.query.sortMode == value ? 1 : 0)
            }
            .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
            .background(
              store.query.sortMode == value ? Color(.systemFill) : .clear,
              in: .capsule
            )
          }
        }
        
        Divider()
          .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
        
        ForEach(store.availableSortOrders, id: \.rawValue) { value in
          Button {
            store.query.sortDirection = value
          } label: {
            HStack {
              Text(value.description)
              
              Spacer(minLength: 34)
              
              Image(systemName: "checkmark.circle.fill")
                .opacity(store.query.sortDirection == value ? 1 : 0)
            }
            .padding(EdgeInsets(top: 8.0, leading: 11, bottom: 8.0, trailing: 11))
            .background(
              store.query.sortDirection == value ? Color(.systemFill) : .clear,
              in: .capsule
            )
          }
        }
      }
      .padding(EdgeInsets(top: 11.0, leading: 8.0, bottom: 11.0, trailing: 8.0))
      .presentationCompactAdaptation(.popover)
    }
  }
  
  @ViewBuilder private func infoView(query: QueryType) -> some View {
    Button {
      store.send(.didSelectShowInfo)
    } label: {
      switch store.queryType {
      case let .querySet(set, _):
        HStack(spacing: 8.0) {
          IconLazyImage(URL(string: set.iconSvgUri)).frame(width: 25, height: 25, alignment: .center)
          Text(store.title).multilineTextAlignment(.leading).font(.headline).lineLimit(1)
        }
        .frame(minHeight: 44.0, alignment: .center)
        .padding(EdgeInsets(top: 0, leading: 13.0, bottom: 0, trailing: 16))
        .glassEffect(.regular.interactive())
        
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
          Text(code.uppercased()).foregroundStyle(.secondary).fontWidth(.condensed)
        }
      }
    }
  }
}
