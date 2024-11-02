import CardDetail
import ComposableArchitecture
import DesignComponents
import ScryfallKit
import SwiftUI
import Networking

@main
struct RunnerApp: App {
  @State var cards: [ScryfallClient.MagicCardModel] = []
  @State var card: ScryfallClient.MagicCardModel?
  
  let client = ScryfallClient()
  
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        PageView<ScryfallClient>(
          store: Store(
            initialState: PageFeature<ScryfallClient>.State(
              cards: cards
            ), reducer: {
              PageFeature<ScryfallClient>(client: client)
            }
          ), client: client
        )
        .containerRelativeFrame(.horizontal)
      }
      .task {
        do {
          cards = try await client.searchCards(query: "layout=transform").data
            .compactMap { $0 }
        } catch {
          
        }
      }
    }
  }
}
