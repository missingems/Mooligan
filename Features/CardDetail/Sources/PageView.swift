import ComposableArchitecture
import SwiftUI
import Networking

public struct PageView<Client: MagicCardDetailRequestClient>: View {
  let store: StoreOf<PageFeature<Client>>
  
  public init(client: Client, cards: [Client.MagicCardModel]) {
    self.store = Store(
      initialState: PageFeature<Client>.State(cards: cards), reducer: {
        PageFeature<Client>(client: client)
      }
    )
  }
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 0) {
        ForEachStore(
          store.scope(state: \.cards, action: \.cards)
        ) { store in
          CardDetailView(store: store).containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
  }
}
