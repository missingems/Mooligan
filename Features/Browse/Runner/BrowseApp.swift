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
            initialState: Feature.State(selectedSet: nil, sets: []),
            reducer: {
              Browse.Feature()
            }, withDependencies: { value in
              value.gameSetRequestClient = ScryfallClient(networkLogLevel: .minimal)
            }
          )
        )
      }
    }
  }
}
