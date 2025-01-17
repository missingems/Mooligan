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
  private var numberOfColumns: Double = 2
  @State private var contentWidth: CGFloat?
  
  init(store: StoreOf<Feature>) {
    self.store = store
  }
  
  var body: some View {
    ScrollView(.vertical) {
      LazyVGrid(
        columns: [GridItem](
          repeating: GridItem(
            spacing: 8.0,
            alignment: .center
          ),
          count: Int(numberOfColumns)
        ),
        spacing: 13
      ) {
        if let contentWidth, contentWidth > 0, let dataSource = store.dataSource {
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
                callToActionHorizontalOffset: 5,
                priceVisibility: .display(usdFoil: cardInfo.card.getPrice(for: .usdFoil), usd: cardInfo.card.getPrice(for: .usd))
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
      }
      .onGeometryChange(
        for: CGFloat.self,
        of: { proxy in
          proxy.size.width
        }, action: { newValue in
          guard contentWidth == nil, newValue > 0 else {
            return
          }
          
          contentWidth = (newValue - ((numberOfColumns - 1) * 8.0)) / numberOfColumns
        }
      )
      .safeAreaPadding(.horizontal, nil)
      .placeholder(store.mode.isPlaceholder)
      .scrollDisabled(store.mode.isPlaceholder)
    }
    .scrollPosition($store.scrollPosition)
    .scrollBounceBehavior(.basedOnSize)
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(store.title)
    .searchable(
      text: Binding(get: {
        store.query.name
      }, set: { newValue in
        if newValue != store.query.name {
          store.query.name = newValue
        }
      }),
      placement: .navigationBarDrawer(displayMode: .always),
      prompt: store.searchPlaceholder
    )
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        if case let .querySet(value, _) = store.queryType, let iconURL = URL(string: value.iconSvgUri) {
          Button("Info", systemImage: "info.circle") {
            store.send(.didSelectShowInfo)
          }
          .labelStyle(.iconOnly)
          .disabled(store.isShowingInfo)
          .popover(
            isPresented: $store.isShowingInfo,
            attachmentAnchor: .rect(.bounds),
            content: {
              VStack(spacing: 0) {
                HStack {
                  Text("Set Symbol")
                  Spacer(minLength: 55)
                  IconLazyImage(iconURL, tintColor: .secondary).frame(width: 21, height: 21, alignment: .center)
                }
                .padding(.vertical, 11.0)
                .safeAreaPadding(.horizontal, nil)
                
                Divider()
                
                HStack {
                  Text("Set Code")
                  Spacer(minLength: 55)
                  Text(value.code.uppercased()).foregroundStyle(.secondary).fontDesign(.monospaced)
                }
                .padding(.vertical, 11.0)
                .safeAreaPadding(.horizontal, nil)
                
                if let date = store.setReleasedDate {
                  Divider()
                  
                  HStack {
                    Text("Released Date")
                    Spacer(minLength: 55)
                    Text(date).foregroundStyle(.secondary)
                  }
                  .padding(.vertical, 11.0)
                  .safeAreaPadding(.horizontal, nil)
                }
                
                Divider()
                
                HStack {
                  Text("Number of Cards")
                  Spacer(minLength: 55)
                  Text("\(value.cardCount)").foregroundStyle(.secondary)
                }
                .padding(.vertical, 11.0)
                .safeAreaPadding(.horizontal, nil)
              }
              .presentationCompactAdaptation(.popover)
              .presentationBackground {
                Color.clear
              }
            }
          )
          
          Menu("Info", systemImage: "line.3.horizontal.decrease.circle") {
            Picker("SORT BY", selection: $store.query.sortMode) {
              ForEach(store.availableSortModes) { value in
                Text(value.description)
              }
            }
            .labelsVisibility(.visible)
            
            Picker("SORT ORDER", selection: $store.query.sortDirection) {
              ForEach(store.availableSortOrders) { value in
                Text(value.description)
              }
            }
            .labelsVisibility(.visible)
          }
          .labelStyle(.iconOnly)
        }
      }
    }
    .task {
      store.send(.viewAppeared)
    }
  }
}
