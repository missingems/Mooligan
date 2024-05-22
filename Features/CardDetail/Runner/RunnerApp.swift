import DesignComponents
import SwiftUI
import CardDetail

@main
struct RunnerApp: App {
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
      }
    }
  }
}
