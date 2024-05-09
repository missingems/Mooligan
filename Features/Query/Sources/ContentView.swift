import ComposableArchitecture
import Networking
import ScryfallKit
import SwiftUI

public struct ContentView: View {
  private var store: StoreOf<Feature<ScryfallClient>>
  
  public init(query: QueryType) {
    store =  Store(initialState: Feature.State(queryType: query)) {
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

#Preview {
  ContentView(query: .set(MockGameSet(), page: 0))
}

struct MockGameSet: GameSet {
  var isParent: Bool? = false
  var id = UUID()
  var code = "OTJ"
  var numberOfCards = 1
  var name = "Stub"
  var iconURL = URL(string: "https://mooligan.com")
}
