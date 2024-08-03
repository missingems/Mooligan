import CardDetail
import DesignComponents
import ScryfallKit
import SwiftUI
import Networking

@main
struct RunnerApp: App {
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
//        RootView(
//          card: MagicCardBuilder<MockMagicCardColor>().with(name: "test").build(),
//          client: ScryfallClient(networkLogLevel: .minimal),
//          entryPoint: .query
        Text("")
      }
    }
  }
}
