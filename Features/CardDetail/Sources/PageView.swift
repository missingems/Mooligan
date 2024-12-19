import ComposableArchitecture
import DesignComponents
import VariableBlur
import SwiftUI
import Networking

public struct PageView<Client: MagicCardDetailRequestClient>: View {
  let store: StoreOf<PageFeature<Client>>
  
  public init(client: Client, cards: [Client.MagicCardModel]) {
    store = Store(
      initialState: PageFeature<Client>.State(cards: cards),
      reducer: {
        PageFeature<Client>(client: client)
      }
    )
  }
  
  public var body: some View {
    GeometryReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 0) {
          ForEach(
            Array(store.scope(state: \.cards, action: \.cards))
          ) { store in
            CardDetailView(geometryProxy: proxy, store: store).containerRelativeFrame(.horizontal)
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.paging)
      .background(.black)
    }
  }
}
