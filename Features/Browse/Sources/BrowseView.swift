import ComposableArchitecture
import ScryfallKit
import SwiftUI
import Networking

public struct BrowseView<Client: BrowseRequestClient>: View {
  private var store: StoreOf<Feature<Client>>
  
  public init(store: StoreOf<Feature<Client>>) {
    self.store = store
  }
  
  public var body: some View {
    List(store.sets) { data in
      VStack(alignment: .leading) {
        Text(data.name)
        Text(data.id.uuidString).font(.caption)
        Text(data.code).font(.caption)
      }
    }
    .onAppear {
      store.send(.viewAppeared)
    }
  }
}
