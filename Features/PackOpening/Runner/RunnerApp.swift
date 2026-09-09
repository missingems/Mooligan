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
    // look at the wrapper, the tear and the reveal.
    prepareDependencies {
      $0.boosterPackClient = MockBoosterPackClient()
      $0.boosterPoolSource = MockBoosterPoolSource()
      // The runner is meant to be entirely offline: without these it would sit
      // in the preparing phase waiting on odds and on card art that its mock
      // cards have no real URLs for.
      $0.boosterOddsSource = MockBoosterOddsSource()
      $0.packImagePrefetcher = ImmediatePackImagePrefetcher()
    }
  }

  /// The runner has no set list to open a pack from, so it stands one up.
  private var product: PackProduct {
    PackProduct(set: MockGameSetRequestClient.mockSets[0], kind: .play)
  }

  var body: some Scene {
    WindowGroup {
      PackSessionView(
        store: Store(initialState: PackSessionFeature.State(product: product)) {
          PackSessionFeature()
        }
      )
    }
  }
}
