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
        cards = [
          try? await client.searchCards(query: "layout=normal").data.first,
          try? await client.searchCards(query: "layout=split").data.first,
          try? await client.searchCards(query: "layout=flip").data.first,
          try? await client.searchCards(query: "layout=transform").data.first,
          try? await client.searchCards(query: "layout=modal_dfc").data.first,
          try? await client.searchCards(query: "layout=meld").data.first,
          try? await client.searchCards(query: "layout=leveler").data.first,
          try? await client.searchCards(query: "layout=class").data.first,
          try? await client.searchCards(query: "layout=case").data.first,
          try? await client.searchCards(query: "layout=saga").data.first,
          try? await client.searchCards(query: "layout=adventure").data.first,
          try? await client.searchCards(query: "layout=mutate").data.first,
          try? await client.searchCards(query: "layout=prototype").data.first,
          try? await client.searchCards(query: "layout=battle").data.first,
          try? await client.searchCards(query: "layout=planar").data.first,
          try? await client.searchCards(query: "layout=scheme").data.first,
          try? await client.searchCards(query: "layout=vanguard").data.first,
          try? await client.searchCards(query: "layout=token").data.first,
          try? await client.searchCards(query: "layout=double_faced_token").data.first,
          try? await client.searchCards(query: "layout=emblem").data.first,
          try? await client.searchCards(query: "layout=augment").data.first,
          try? await client.searchCards(query: "layout=host").data.first,
          try? await client.searchCards(query: "layout=art_series").data.first,
          try? await client.searchCards(query: "layout=reversible_card").data.first
        ].compactMap { $0 }
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
