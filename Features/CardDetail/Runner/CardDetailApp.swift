import ComposableArchitecture
import DesignComponents
import SwiftUI
import CardDetail
import ScryfallKit

@main
struct BrowseApp: App {
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
