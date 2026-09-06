import CardDetail
import ComposableArchitecture
import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

@main
struct RunnerApp: App {
  init() {
    DesignComponents.Main().setup()
  }

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        CardDetail.RootView(
          store: Store(
            initialState: CardDetailFeature.State(
              card: .mock(),
              queryType: .search(
                SearchQuery(page: 1, sortMode: .name, sortDirection: .asc)
              )
            )
          ) {
            CardDetailFeature()
          }
        )
      }
    }
  }
}
