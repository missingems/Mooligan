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
          ForEach(dataSource.cardDetails.indices, id: \.self) { index in
            let card = dataSource.cardDetails[index].card
            
            let layout = CardView.LayoutConfiguration(
              rotation: .portrait,
              maxWidth: contentWidth
            )
            
            Button {
              store.send(.didSelectCard(card))
            } label: {
              CardView(
                card: card,
                layoutConfiguration: layout,
                callToActionHorizontalOffset: 5,
                priceVisibility: .hidden
              )
            }
            .frame(width: layout.size.width, height: layout.size.height, alignment: .center)
            .buttonStyle(.sinkableButtonStyle)
            .task {
              store.send(.loadMoreCardsIfNeeded(displayingIndex: index))
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
      .padding(.horizontal, 11)
    }
    .modifier(Placeholder(isPlaceholder: store.mode.isPlaceholder))
    .scrollDisabled(store.mode.isPlaceholder)
    .background(Color(.secondarySystemBackground).ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .task {
      store.send(.viewAppeared)
    }
  }
}
