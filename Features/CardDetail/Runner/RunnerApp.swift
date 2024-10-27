import CardDetail
import DesignComponents
import SwiftUI
import Networking
import ScryfallKit

@main
struct RunnerApp: App {
  @State var cards: [ScryfallClient.MagicCardModel] = []
  @State var card: ScryfallClient.MagicCardModel?
  @State private var selectedIndex: Int? = 0
  
  let client = ScryfallClient()
  
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      ScrollView(.horizontal) {
        LazyHStack(spacing: 0) {
          ForEach(cards) { card in
            RandomCardView(card: card).containerRelativeFrame(.horizontal)
          }
        }
        .scrollTargetLayout()
      }
      .scrollIndicators(.hidden)
      .scrollTargetBehavior(.paging)
      .scrollPosition(id: $selectedIndex)
      .task {
        cards = try! await withThrowingTaskGroup(of: ScryfallClient.MagicCardModel?.self) { group in
          for layout in [
            "split", "flip", "transform", "modal_dfc", "meld", "leveler",
            "class", "case", "saga", "adventure", "mutate", "prototype", "battle",
            "scheme", "vanguard", "double_faced_token", "emblem",
            "augment", "reversible_card"
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
        }.compactMap { $0 }
      }
    }
  }
}

struct RandomCardView: View {
  let card: ScryfallClient.MagicCardModel
  let client = ScryfallClient()
  
  var body: some View {
    RootView(
      card: card,
      client: client,
      entryPoint: .query
    )
  }
}
