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
          ForEach(store.dataSource.model.indices, id: \.self) { index in
            Button(
              action: {
                print("Selected")
              }, label: {
                let width = ((proxy.size.width - 24) / 2.0).rounded()
                let height = width.multiplied(byRatio: .heightToWidth)
                
                Group {
                  let model = store.dataSource.model[index]
                  
                  if let url = model.getImageURL() {
                    AmbientWebImage(url: url)
                  } else {
                    Text(model.getName()).multilineTextAlignment(.center)
                  }
                }
                .frame(
                  width: width,
                  height: height,
                  alignment: .center
                )
              }
            )
            .buttonStyle(.sinkableButtonStyle)
            .task {
              store.send(.loadMoreCardsIfNeeded(currentIndex: index))
            }
          }
        }
        .safeAreaPadding(.horizontal, 10.0)
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
