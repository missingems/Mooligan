import CardDetail
import ComposableArchitecture
import DesignComponents
import ScryfallKit
import SwiftUI
import Networking

@main
struct RunnerApp: App {
  @State var cards: [ScryfallClient.MagicCardModel] = []
  
  let client = ScryfallClient()
  
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        if cards.isEmpty == false {
          PageView(client: client, cards: cards)
        }
      }
      .task {
        do {
          cards = try await client.searchCards(query: "layout=flip").data.compactMap { $0 }
        } catch {
          
        }
      }
    }
  }
}
