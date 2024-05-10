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
        RootView(queryType: .set(MockGameSet(), page: 0))
      }
    }
  }
}
