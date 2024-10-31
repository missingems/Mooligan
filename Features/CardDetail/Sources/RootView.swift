import ComposableArchitecture
import Networking
import SwiftUI

public enum EntryPoint<Client: MagicCardDetailRequestClient>: Equatable, Sendable {
  case query
  case set(Client.MagicCardSet)
}

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
    ScrollView(.horizontal) {
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
    .scrollTargetBehavior(.viewAligned)
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackgroundVisibility(.visible)
    .navigationTitle("test")
    .background(.black)
    .scrollIndicators(.hidden)
  }
}

public struct RootView<Client: MagicCardDetailRequestClient>: View {
  private let store: StoreOf<Feature<Client>>
  
  public init(
    card: Client.MagicCardModel,
    client: Client,
    entryPoint: EntryPoint<Client>
  ) {
    store = Store(
      initialState: Feature.State(
        card: card,
        entryPoint: entryPoint
      )
    ) {
      Feature(client: client)
    }
  }
  
  public var body: some View {
    CardDetailView(store: store)
  }
}
