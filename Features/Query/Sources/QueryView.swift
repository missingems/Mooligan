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
        ForEach(
          Array(
            zip(
              store.dataSource.cardDetails,
              store.dataSource.cardDetails.indices
            )
          ),
          id: \.0
        ) { value in
          let card = value.0.card
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
                priceVisibility: .hidden
              )
            }
          )
          .frame(width: 175, height: 300, alignment: .center)
          .buttonStyle(.sinkableButtonStyle)
          .task {
//            store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
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
