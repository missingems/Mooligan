import ComposableArchitecture
import Networking
import DesignComponents
import SwiftUI
import Query

@main
struct BrowseApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        RootView(query: .set(MockGameSet(), page: 0))
      }
    }
  }
}
