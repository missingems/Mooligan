import ComposableArchitecture
import DesignComponents
import Networking
import PackOpening
import SwiftUI

@main
struct RunnerApp: App {
  init() {
    DesignComponents.Main().setup()

    // The runner never talks to Scryfall or the bulk database: it exists to
    // look at the machine, the wrapper and the tear.
    prepareDependencies {
      $0.boosterPackClient = MockBoosterPackClient()
      $0.boosterPoolSource = MockBoosterPoolSource()
    }
  }

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        PackOpening.RootView(
          store: Store(initialState: PackOpeningFeature.State()) {
            PackOpeningFeature()
          }
        )
      }
    }
  }
}
