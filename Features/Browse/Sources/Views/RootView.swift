import ComposableArchitecture
import ScryfallKit
import SwiftUI

public struct RootView: View {
  private let store = Store(
    initialState: Feature.State(),
    reducer: {
      Feature(client: ScryfallClient(networkLogLevel: .minimal))
    }
  )
  
  public init() {}
  
  public var body: some View {
    SetsView(store: store)
      .navigationTitle(store.title)
  }
}
