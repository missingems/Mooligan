import CardDetail
import ComposableArchitecture
import DesignComponents
import ScryfallKit
import SwiftUI
import Networking

@main
struct RunnerApp: App {
  @State var cards: [Card] = []
  
  let client = ScryfallClient()
  
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        if cards.isEmpty == false {
          PageView(cards: cards)
        }
      }
      .task {
        do {
          async let normals = try await client.searchCards(query: "layout=normal").data.compactMap { $0 }
          async let transforms = try await client.searchCards(query: "layout=transform").data.compactMap { $0 }
          async let flips = try await client.searchCards(query: "layout=flip").data.compactMap { $0 }
          async let splits = try await client.searchCards(query: "layout=split").data.compactMap { $0 }
          async let modaldfcs = try await client.searchCards(query: "layout=modal_dfc").data.compactMap { $0 }
          
          cards = try await [normals, transforms, flips, splits, modaldfcs].joined().shuffled()
        } catch {
          
        }
      }
    }
  }
}
