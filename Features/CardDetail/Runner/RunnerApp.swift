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
          card: MagicCardBuilder<MockMagicCardColor>().with(name: "Eidolon").with(collectorNumber: "123").build(),
          client: MockMagicCardDetailRequestClient(),
          entryPoint: .query
        )
      }
    }
  }
}
