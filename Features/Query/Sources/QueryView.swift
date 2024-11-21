import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI
import NukeUI

struct QueryView<Client: MagicCardQueryRequestClient>: View {
  private var store: StoreOf<Feature<Client>>
  
  init(store: StoreOf<Feature<Client>>) {
    self.store = store
  }
  
  var body: some View {
    GeometryReader { proxy in
      let width = (proxy.size.width - 24) / 2
      
      ScrollView {
        LazyVGrid(
          columns: [GridItem](
            repeating: GridItem(),
            count: 2
          ),
          spacing: 8
        ) {
          ForEach(store.dataSource.model) { card in
            Button(
              action: {
                store.send(.didSelectCard(card))
              }, label: {
//                CardView(
//                  card: card,
//                  configuration: .init(rotation: .portrait, layout: .fixedWidth(width)),
//                  shouldShowPrice: false
//                )
                CardView(
                  imageURL: card.getImageURL(),
                  backImageURL: card.getCardFace(for: .back).getImageURL(),
                  isFlippable: card.isFlippable,
                  isRotatable: card.isRotatable,
                  layoutConfiguration: .init(rotation: .portrait, layout: .fixedWidth(width)),
                  usdPrice: nil, usdFoilPrice: nil, shouldShowPrice: false) {
                    print("on flip")
                  }
              }
            )
            .buttonStyle(.sinkableButtonStyle)
          }
        }
        .padding(.horizontal, 8)
      }
      .background {
        Color
          .primary
          .colorInvert()
          .opacity(0.02)
          .ignoresSafeArea()
      }
      .navigationBarTitleDisplayMode(.inline)
      .task {
        store.send(.viewAppeared)
      }
    }
  }
}
