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
          card: MagicCardBuilder<MockMagicCardColor>()
            .with(name: "Eidolon")
            .with(manaCost: "{R}")
            .with(collectorNumber: "123")
            .with(typeline: "Creature - Enchanment")
            .build(),
          client: MockMagicCardDetailRequestClient(),
          entryPoint: .query
        )
      }
    }
  }
}
