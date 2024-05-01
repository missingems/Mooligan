import ComposableArchitecture
import SwiftUI
import Browse
import ScryfallKit

@main
struct BrowseApp: App {
  var body: some Scene {
    WindowGroup {
      BrowseView(store: .init(initialState: Feature.State(), reducer: {
        Feature(client: ScryfallClient.init(networkLogLevel: .minimal))
      }))
    }
  }
}
