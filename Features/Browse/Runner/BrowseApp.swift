import ComposableArchitecture
import DesignComponents
import SwiftUI
import Browse

@main
struct BrowseApp: App {
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        RootView()
      }
    }
  }
}
