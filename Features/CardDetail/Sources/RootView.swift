import ComposableArchitecture
import Networking
import SwiftUI

public enum EntryPoint<Client: MagicCardDetailRequestClient>: Equatable {
  case query
  case set(Client.MagicCardSet)
}

public struct RootView<Client: MagicCardDetailRequestClient>: View {
  private let store: StoreOf<Feature<Client>>
  
  public init(
    card: Client.MagicCardModel,
    client: Client,
    entryPoint: EntryPoint<Client>
  ) {
    store = Store(initialState: Feature.State(card: card, entryPoint: entryPoint)) {
      Feature(client: client)
    }
  }
  
  public var body: some View {
    CardDetailView(store: store)
  }
}
