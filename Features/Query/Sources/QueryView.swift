import ComposableArchitecture
import DesignComponents
import Featurist
import Networking
import Shimmer
import SwiftUI
import NukeUI

struct Placeholder: ViewModifier {
  let isPlaceholder: Bool
  
  func body(content: Content) -> some View {
    if isPlaceholder {
      content.redacted(reason: .placeholder)
    } else {
      content
    }
  }
}

struct QueryView: View {
  private var store: StoreOf<Feature>
  @State private var numberOfColumns: Double = 2
  @State private var contentWidth: CGFloat = 0
  
  init(store: StoreOf<Feature>) {
    self.store = store
  }
  
  var body: some View {
    let _ = Self._printChanges()
    ScrollView(.vertical) {
      LazyVGrid(
        columns: [GridItem](
          repeating: GridItem(
            .flexible(minimum: 10, maximum: .infinity),
            spacing: 8.0,
            alignment: .center
          ),
          count: Int(numberOfColumns)
        ),
        spacing: 13
      ) {
        ForEach(
          Array(
            zip(
              store.mode.dataSource.cards,
              store.mode.dataSource.cards.indices
            )
          ),
          id: \.0
        ) { value in
          let card = value.0
          let index = value.1
          
          Button(
            action: {
              store.send(.didSelectCard(card))
            }, label: {
              CardView(
                card: card,
                layoutConfiguration: CardView.LayoutConfiguration(
                  rotation: .portrait,
                  maxWidth: (contentWidth - ((numberOfColumns - 1) * 8.0)) / numberOfColumns
                ),
                callToActionHorizontalOffset: 5,
                priceVisibility: .display(usdFoil: card.prices.usdFoil, usd: card.prices.usd)
              )
            }
          )
          .buttonStyle(.sinkableButtonStyle)
          .frame(
            idealHeight: (
              (contentWidth - ((numberOfColumns - 1) * 8.0)) / numberOfColumns / MagicCardImageRatio.widthToHeight.rawValue
            )
            .rounded() + 25.0
          )
          .task {
            store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
          }
        }
        .modifier(Placeholder(isPlaceholder: store.mode.isPlaceholder))
      }
      .onGeometryChange(
        for: CGFloat.self,
        of: { proxy in
          proxy.size.width
        }, action: { newValue in
          contentWidth = newValue
        }
      )
      .padding(.horizontal, 11)
    }
    .scrollDisabled(store.mode.isPlaceholder)
    .background(Color(.secondarySystemBackground).ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .task {
      store.send(.viewAppeared)
    }
  }
}
