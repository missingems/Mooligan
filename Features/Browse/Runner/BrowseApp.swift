import ComposableArchitecture
import SwiftUI
import Browse

@main
struct BrowseApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView(
        store: Store(initialState: Feature.State(), reducer: {
          Feature()
        })
      )
    }
  }
}
