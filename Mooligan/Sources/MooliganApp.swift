import Browse
import ComposableArchitecture
import SwiftUI

@main
struct MooliganApp: App {
  var body: some Scene {
    WindowGroup {
      BrowseView(
        store: Store(
          initialState: Feature.State(),
          reducer: {
            Feature()
        })
      )
    }
  }
}

