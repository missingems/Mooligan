import ComposableArchitecture
import ScryfallKit
import SwiftUI

public struct RootView: View {
  public init() {}
  
  public var body: some View {
    SetsView(
      store: Store(
        initialState: Feature.State(),
        reducer: {
          Feature(client: ScryfallClient(networkLogLevel: .minimal))
        }
      )
    )
  }
}
