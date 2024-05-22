import ComposableArchitecture
import Networking
import SwiftUI

public struct RootView<Client: MagicCardDetailRequestClient>: View {
  private let store: StoreOf<Feature<Client>>
  
  public init(card: Client.MagicCardModel, client: Client) {
    store = Store(initialState: Feature.State(card: card)) {
      Feature(client: client)
    }
  }
  
  public var body: some View {
    CardDetailView(store: store)
  }
}
