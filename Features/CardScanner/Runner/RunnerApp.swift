import CardScanner
import ComposableArchitecture
import DesignComponents
import SwiftUI

@main
struct RunnerApp: App {
  init() {
    DesignComponents.Main().setup()
  }

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        RootView(
          store: Store(initialState: CardScannerFeature.State()) {
            CardScannerFeature()
          }
        )
      }
    }
  }
}
