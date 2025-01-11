import ComposableArchitecture
import DesignComponents
import SwiftUI
import Browse
import ScryfallKit

@main
struct BrowseApp: App {
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        RootView(
          store: Store(
            initialState: BrowseFeature.State(selectedSet: nil, sets: []),
            reducer: {
              Browse.BrowseFeature()
            }, withDependencies: { value in
              value.gameSetRequestClient = ScryfallClient(networkLogLevel: .minimal)
            }
          )
        )
      }
    }
  }
}
