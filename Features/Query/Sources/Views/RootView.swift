import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct RootView: View {
  private var store: StoreOf<Feature<ScryfallClient>>
  
  public init(query: QueryType) {
    store = Store(initialState: Feature.State(queryType: query)) {
      Feature(client: ScryfallClient(networkLogLevel: .minimal))
    }
  }
  
  public var body: some View {
    Text("\(store.cards.count)")
      .padding()
      .onAppear(perform: {
        store.send(.viewAppeared)
      })
  }
}
