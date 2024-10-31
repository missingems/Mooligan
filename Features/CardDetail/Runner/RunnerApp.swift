import CardDetail
import DesignComponents
import SwiftUI
import Networking
import ScryfallKit

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
        RandomCardView(cards: cards).containerRelativeFrame(.horizontal)
      }
      .task {
        cards = try! await withThrowingTaskGroup(of: ScryfallClient.MagicCardModel?.self) { group in
          for layout in [
            "split"
          ] {
            group.addTask {
              try? await client.searchCards(query: "layout=\(layout)").data.first
            }
          }
          
          var results: [ScryfallClient.MagicCardModel?] = []
          for try await card in group {
            results.append(card)
          }
          
          return results
        }
        .compactMap { $0 }
      }
    }
  }
}

struct RandomCardView: View {
  let cards: [ScryfallClient.MagicCardModel]
  let client = ScryfallClient()
  
  var body: some View {
    PageView(
      store: .init(
        initialState: PageFeature.State(
          contentOffset: 0,
          cards: cards
        ), reducer: {
          PageFeature<ScryfallClient>(client: client)
        }
      ), client: client
    )
  }
}

