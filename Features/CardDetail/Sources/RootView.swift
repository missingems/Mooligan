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
    VStack {
      RootView(
        card: store.cards.first!,
        client: client,
        contentOffset: store.$contentOffset,
        entryPoint: EntryPoint<Client>.query
      )
      
      Button {
      } label: {
        Text("store: \(store.contentOffset)")
      }
    }
  }
}

public struct RootView<Client: MagicCardDetailRequestClient>: View {
  private let store: StoreOf<Feature<Client>>
  
  public init(
    card: Client.MagicCardModel,
    client: Client,
    contentOffset: Shared<CGFloat>,
    entryPoint: EntryPoint<Client>
  ) {
    store = Store(
      initialState: Feature.State(
        card: card,
        contentOffset: contentOffset,
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
