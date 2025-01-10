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
        if contentWidth > 0, let dataSource = store.dataSource {
          ForEach(dataSource.cardDetails.indices, id: \.self) { index in
            let card = dataSource.cardDetails[index].card
            
//            Button(
//              action: {
//                store.send(.didSelectCard(card))
//              }, label: {
//                
//              }
//            )
            let layout = CardView.LayoutConfiguration(
              rotation: .portrait,
              maxWidth: (contentWidth - ((numberOfColumns - 1) * 8.0)) / numberOfColumns
            )
                
            CardRemoteImageView(
              url: card.getImageURL(type: .normal)!,
              isLandscape: layout.rotation == .landscape,
              isTransformed: false,
              size: layout.size
            )
//            .frame(width: layoutConfiguration.size.width, height: layoutConfiguration.size.height, alignment: .center)
            
//            CardView(
//              card: card,
//              layoutConfiguration: CardView.LayoutConfiguration(
//                rotation: .portrait,
//                maxWidth: (contentWidth - ((numberOfColumns - 1) * 8.0)) / numberOfColumns
//              ),
//              callToActionHorizontalOffset: 5,
//              priceVisibility: .hidden
//            )
//            .onTapGesture {
//              store.send(.didSelectCard(card))
//            }
//            .buttonStyle(.sinkableButtonStyle)
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
          if contentWidth != newValue {
            contentWidth = newValue
          }
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
