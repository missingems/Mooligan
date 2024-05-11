import Networking
import SwiftUI
import Query

@main
struct RunnerApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        RootView(queryType: .set(MockGameSet(), page: 0))
      }
    }
  }
}
