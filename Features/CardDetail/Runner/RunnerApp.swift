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
//        if let card = MagicCardFixture.stub.last {
//          RootView(
//            card: card,
//            client: ScryfallClient(networkLogLevel: .minimal),
//            entryPoint: .query
//          )
//        }
      }
    }
  }
}
