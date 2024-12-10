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
          async let transforms = try await client.searchCards(query: "layout=transform").data.compactMap { $0 }
//          async let flips = try await client.searchCards(query: "layout=flip").data.compactMap { $0 }
//          async let split = try await client.searchCards(query: "layout=split").data.compactMap { $0 }
//          async let modaldfcs = try await client.searchCards(query: "layout=modal_dfc").data.compactMap { $0 }
          
          cards = try await transforms
        } catch {
          
        }
      }
    }
  }
}
