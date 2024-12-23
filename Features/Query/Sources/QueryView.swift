import ComposableArchitecture
import DesignComponents
import Featurist
import Networking
import SwiftUI
import NukeUI

struct QueryView<Client: MagicCardQueryRequestClient>: View {
  private var store: StoreOf<Feature<Client>>
  @State private var itemWidth: CGFloat?
  
  init(store: StoreOf<Feature<Client>>) {
    self.store = store
  }
  
  var body: some View {
    ScrollView {
      if let itemWidth {
        LazyVGrid(
          columns: [GridItem](
            repeating: GridItem(),
            count: 2
          ),
          spacing: 8
        ) {
          ForEach(Array(zip(store.dataSource.model, store.dataSource.model.indices)), id: \.0) { value in
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
                  priceVisibility: .display(usdFoil: card.getPrices().usdFoil, usd: card.getPrices().usd)
                )
              }
            )
            .buttonStyle(.sinkableButtonStyle)
            .frame(idealHeight: (itemWidth / MagicCardImageRatio.widthToHeight.rawValue).rounded() + 21.0 + 18.0)
            .task {
              store.send(.loadMoreCardsIfNeeded(currentIndex: index))
            }
          }
        }
        .padding(.horizontal, 8)
      }
    }
    .onGeometryChange(for: CGFloat.self, of: { proxy in
      return proxy.size.width
    }, action: { newValue in
      itemWidth = (newValue - 24) / 2
    })
    .background(Color(.secondarySystemBackground).ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .task {
      store.send(.viewAppeared)
    }
  }
}
