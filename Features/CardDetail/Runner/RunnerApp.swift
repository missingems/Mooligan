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
  @State var contentOffset: CGFloat = 0
  @State var navigationBarVisibility: Visibility = .visible
  
  let client = ScryfallClient()
  
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        ScrollView(.horizontal) {
          LazyHStack(spacing: 8.0) {
            ForEach(cards) { card in
              RandomCardView(card: card)
                .containerRelativeFrame(.horizontal)
                .navigationBarTitleDisplayMode(.inline)
            }
            .scrollTargetLayout()
            .toolbarBackgroundVisibility(navigationBarVisibility, for: .navigationBar)
            .onChange(of: contentOffset) { oldValue, newValue in
              if newValue < 0 {
                navigationBarVisibility = .visible
              } else {
                navigationBarVisibility = .hidden
              }
            }
          }
          .background(.black)
          .scrollIndicators(.hidden)
          .scrollTargetBehavior(.viewAligned)
          .task {
            cards = try! await withThrowingTaskGroup(of: ScryfallClient.MagicCardModel?.self) { group in
              for layout in [
                "split"
                //                "split", "flip", "transform", "modal_dfc", "meld", "leveler",
                //                "class", "case", "saga", "adventure", "mutate", "prototype", "battle",
                //                "scheme", "vanguard", "double_faced_token", "emblem",
                //                "augment", "reversible_card"
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
  }
}

struct RandomCardView: View {
  let card: ScryfallClient.MagicCardModel
  let client = ScryfallClient()
  
  var body: some View {
    PageView(
      store: .init(
        initialState: PageFeature.State(
          contentOffset: 0,
          cards: [card]
        ), reducer: {
          PageFeature<ScryfallClient>(client: client)
        }
      ), client: client
    )
  }
}
