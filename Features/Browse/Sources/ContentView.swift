import ComposableArchitecture
import SwiftUI
import Networking

public struct ContentView: View {
  private var store: StoreOf<Feature>
  
  public init(store: StoreOf<Feature>) {
    self.store = store
  }
  
  public var body: some View {
    List(store.gameSetObjectList.sets, id: \.id) { data in
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

#Preview {
  ContentView(
    store: Store(initialState: Feature.State(), reducer: {
      Feature()
    })
  )
}
