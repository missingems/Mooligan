import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI
import NukeUI

struct QueryView<Client: MagicCardQueryRequestClient>: View {
  @Environment(\.horizontalSizeClass)
  private var sizeClass
  
  @Bindable
  private var store: StoreOf<Feature<Client>>
  
  private var horizontalSpacing: CGFloat {
    spacing * 2
  }
  
  init(store: StoreOf<Feature<Client>>) {
    self.store = store
  }
  
  var body: some View {
    GeometryReader { proxy in
      let proxyWidth = proxy.size.width
      let numberOfColumns = Self.maxNumberOfColumns(width: proxyWidth, spacing: spacing)
      let gridSpacing = CGFloat(numberOfColumns - 1) * spacing
      
      if proxyWidth > 0 {
        let widthPerItem = Self.widthPerItem(
          proxyWidth: proxyWidth,
          gridSpacings: gridSpacing,
          extraPaddings: horizontalSpacing,
          numberOfColumns: numberOfColumns
        )
        
        ScrollView {
          LazyVGrid(
            columns: [GridItem](
              repeating: GridItem(.fixed(min(widthPerItem, Self.maxCardWidth())), spacing: spacing),
              count: numberOfColumns
            ),
            spacing: spacing
          ) {
            ForEach(store.cards) { card in
              Button(
                action: {
                  print("Selected")
                }, label: {
                  AmbientWebImage(
                    url: [card.getImageURL()],
                    width: min(widthPerItem, Self.maxCardWidth())
                  )
                }
              )
              .buttonStyle(.sinkableButtonStyle)
            }
          }
        }
      }
    }
    .onAppear {
      store.send(.viewAppeared)
    }
    .navigationBarTitleDisplayMode(.inline)
  }
}

extension QueryView {
  private var spacing: CGFloat {
    if sizeClass == .regular {
      return 16.0
    } else {
      return 8.0
    }
  }
}

extension QueryView {
  private static func maxCardWidth() -> CGFloat {
    return 233.0
  }
  
  private static func maxNumberOfColumns(width: CGFloat, spacing: CGFloat) -> Int {
    return min(max(1, Int((width / (Self.maxCardWidth() + spacing)).rounded())), 8)
  }
  
  private static func widthPerItem(proxyWidth: CGFloat, gridSpacings: CGFloat, extraPaddings: CGFloat, numberOfColumns: Int) -> CGFloat {
    return max(144.0, ((proxyWidth - gridSpacings - extraPaddings) / CGFloat(numberOfColumns)).rounded())
  }
}

