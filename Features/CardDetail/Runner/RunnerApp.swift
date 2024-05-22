import CardDetail
import DesignComponents
import ScryfallKit
import SwiftUI

@main
struct RunnerApp: App {
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
        RootView(
          card: Card(
            id: UUID(),
            oracleId: "",
            lang: "en",
            printsSearchUri: "",
            rulingsUri: "",
            scryfallUri: "",
            uri: "",
            cmc: 0,
            colorIdentity: [.B],
            keywords: [],
            layout: .adventure,
            legalities: <#T##Card.Legalities#>,
            name: "Test",
            oversized: false,
            reserved: false,
            booster: true,
            borderColor: .black,
            collectorNumber: "123",
            digital: false,
            finishes: [],
            frame: .v2015,
            fullArt: false,
            games: [.paper],
            highresImage: true,
            imageStatus: .highresScan,
            prices: Card.Prices(tix: "", usd: "", usdFoil: "", eur: ""),
            promo: false,
            rarity: .mythic,
            relatedUris: [:],
            releasedAt: "",
            reprint: false,
            scryfallSetUri: "",
            setName: "",
            setSearchUri: URL(string: "")!,
            setType: .funny,
            setUri: "",
            set: "",
            storySpotlight: false,
            textless: false,
            variation: false
          ),
          client: ScryfallClient(networkLogLevel: .minimal)
        )
      }
    }
  }
}
