import CardDetail
import DesignComponents
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
          card: MagicCardFixtures.regular.value,
          client: MockMagicCardDetailRequestClient<MockMagicCard<MockMagicCardColor>>(testConfiguration: .successFlow),
          entryPoint: .query
        )
      }
    }
  }
}
