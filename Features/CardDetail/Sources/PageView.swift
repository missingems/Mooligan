import ComposableArchitecture
import SwiftUI
import Networking

public struct PageView<Client: MagicCardDetailRequestClient>: View {
  let client: Client
  let store: StoreOf<PageFeature<Client>>
  
  public init(
    store: StoreOf<PageFeature<Client>>,
    client: Client
  ) {
    self.store = store
    self.client = client
  }
  
  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 8.0) {
        ForEach(store.cards) { card in
          RootView(
            card: card,
            client: client,
            entryPoint: EntryPoint<Client>.query
          )
          .containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    .scrollTargetBehavior(.viewAligned)
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackgroundVisibility(.visible, for: .navigationBar)
  }
}
