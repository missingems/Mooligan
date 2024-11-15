import ComposableArchitecture
import Networking
import SwiftUI

enum EntryPoint<Client: MagicCardDetailRequestClient>: Equatable, Sendable {
  case query
  case set(Client.MagicCardSet)
}

struct RootView<Client: MagicCardDetailRequestClient>: View {
  private let store: StoreOf<CardDetailFeature<Client>>
  
  var body: some View {
    CardDetailView(store: store)
  }
  
  init(store: StoreOf<CardDetailFeature<Client>>) {
    self.store = store
  }
}
