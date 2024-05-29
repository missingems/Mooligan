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
        RootView(
          card: MagicCardFixture.stub.first!,
          client: ScryfallClient(networkLogLevel: .minimal)
        )
      }
    }
  }
}
