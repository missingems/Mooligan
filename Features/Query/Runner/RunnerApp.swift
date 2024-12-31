import Networking
import SwiftUI
import Query

@main
struct RunnerApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        Query.RootView(
          queryType: .set(
            MockGameSetRequestClient.mockSets[0],
            page: 1
          )
        )
      }
    }
  }
}
