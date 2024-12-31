import ComposableArchitecture
import DesignComponents
import Featurist
import Networking
import SwiftUI
import NukeUI

struct QueryView: View {
  private var store: StoreOf<Feature>
  @State private var itemWidth: CGFloat?
  
  init(store: StoreOf<Feature>) {
    self.store = store
  }
  
  var body: some View {
    let _ = Self._printChanges()
    ScrollView(.vertical) {
      Group {
        if let itemWidth, itemWidth > 0 {
          LazyVGrid(
            columns: [GridItem](
              repeating: GridItem(
                .fixed(itemWidth),
                spacing: 8.0,
                alignment: .center
              ),
              count: 2
            ),
            spacing: 13
          ) {
            ForEach(
              Array(
                zip(
                  store.dataSource.cards,
                  store.dataSource.cards.indices
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
                      maxWidth: itemWidth
                    ),
                    callToActionHorizontalOffset: 5,
                    priceVisibility: .display(
                      usdFoil: card.prices.usdFoil,
                      usd: card.prices.usd
                    )
                  )
                }
              )
              .buttonStyle(.sinkableButtonStyle)
              .frame(
                idealHeight: (
                  itemWidth / MagicCardImageRatio.widthToHeight.rawValue
                )
                .rounded() + 25.0
              )
              .task {
                store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
              }
            }
          }
        } else {
          ProgressView()
        }
      }
      .onGeometryChange(
        for: CGFloat.self,
        of: { proxy in
          proxy.size.width
        }, action: { newValue in
          itemWidth = (newValue - 8.0) / 2
        }
      )
      .padding(.horizontal, 11)
    }
    .background(Color(.secondarySystemBackground).ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .task {
      store.send(.viewAppeared)
    }
  }
}
