import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI
import NukeUI

struct QueryView<Client: MagicCardQueryRequestClient>: View {
  @Environment(\.horizontalSizeClass) private var sizeClass
  private var store: StoreOf<Feature<Client>>
  private var horizontalSpacing: CGFloat { spacing * 2 }
  
  init(store: StoreOf<Feature<Client>>) {
    self.store = store
  }
  
  var body: some View {
    GeometryReader { proxy in
      ScrollView {
        LazyVGrid(
          columns: [GridItem](
            repeating: GridItem(spacing: spacing),
            count: 2
          ),
          spacing: spacing
        ) {
          ForEach(Array(store.dataSource.model.enumerated()), id: \.element) { (offset, element) in
            Button(
              action: {
                store.send(.didSelectCardAtIndex(offset))
              }, label: {
                CardView(
                  card: element,
                  layoutConfiguration: .fixedWidth((proxy.size.width - horizontalSpacing - spacing) / 2),
                  shouldShowPrice: false
                )
              }
            )
            .buttonStyle(.sinkableButtonStyle)
            .task {
              store.send(.loadMoreCardsIfNeeded(currentIndex: offset))
            }
          }
        }
        .safeAreaPadding(.horizontal, spacing)
      }
      .background {
        Color(.secondarySystemGroupedBackground).ignoresSafeArea()
      }
      .navigationBarTitleDisplayMode(.inline)
      .task {
        store.send(.viewAppeared)
      }
    }
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
