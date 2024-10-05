import CardDetail
import DesignComponents
import SwiftUI
import Networking
import ScryfallKit

@main
struct RunnerApp: App {
  @State var card: ScryfallClient.MagicCardModel?
  let client = ScryfallClient(
    
  )
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        if let card {
          RandomCardView(card: card)
        } else {
          ProgressView()
        }
      }
      .task {
        card = try? await client.getRandomCard()
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
