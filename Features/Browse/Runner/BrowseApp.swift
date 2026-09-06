import Browse
import ComposableArchitecture
import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

@main
struct BrowseApp: App {
  init() {
    DesignComponents.Main().setup()
  }

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        RootView(
          store: Store(
            initialState: BrowseFeature.State(),
            reducer: { Browse.BrowseFeature() },
            withDependencies: { $0.gameSetRequestClient = ScryfallClient() }
          )
        )
      }
    }
  }
}
