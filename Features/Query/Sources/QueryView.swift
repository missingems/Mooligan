import ComposableArchitecture
import DesignComponents
import Featurist
import Networking
import Shimmer
import SwiftUI
import NukeUI

struct QueryView: View {
  private var store: StoreOf<Feature>
  private var numberOfColumns: Double = 2
  @State private var contentWidth: CGFloat?
  @State private var search: String = ""
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
    .scrollBounceBehavior(.basedOnSize)
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(store.title)
    .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: store.searchPlaceholder)
    .toolbar {
      ToolbarItem(placement: .principal) {
        if case let .set(set, _) = store.queryType, let url = URL(string: set.iconSvgUri) {
          HStack(spacing: 5) {
            IconLazyImage(url).frame(width: 23, height: 23, alignment: .center).offset(y: -1)
            Text(store.title).font(.headline).multilineTextAlignment(.center)
          }
        }
      }
    }
    .task {
      store.send(.viewAppeared)
    }
  }
}
