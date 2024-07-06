import CardDetail
import DesignComponents
import ScryfallKit
import SwiftUI
import Networking

@main
struct RunnerApp: App {
  init() {
    DesignComponents.Main().setup()
  }
  
  var body: some Scene {
    WindowGroup {
      NavigationView {
//        let card = MockMagicCard().setName("")
        //        if let card = CardBuilder {
        //          RootView(
        //            card: card,
        //            client: ScryfallClient(networkLogLevel: .minimal),
        //            entryPoint: .query
        //          )
        //        }
      }
    }
  }
  
  var magicCard: MockMagicCard<
    MockMagicCardFace<MockMagicCardColor>,
    MockMagicCardColor,
    MockMagicCardLayout,
    MockMagicCardLegalities,
    MockMagicCardPrices,
    MockMagicCardRarity
  > {
    return MockMagicCard(
      id: UUID(),
      language: "en",
      cardFace: MockMagicCardFace(
        magicColorIndicator: <#T##[MockMagicCardColor]?#>,
        magicColors: <#T##[MockMagicCardColor]?#>, manaValue: <#T##Double?#>, artist: <#T##String?#>, flavorText: <#T##String?#>, loyalty: <#T##String?#>, name: <#T##String#>, oracleText: <#T##String?#>, power: <#T##String?#>, printedName: <#T##String?#>, printedText: <#T##String?#>, printedTypeLine: <#T##String?#>, toughness: <#T##String?#>, typeLine: <#T##String?#>),
      colorIdentity: <#[MockMagicCardColor]#>,
      keywords: <#[String]#>,
      layout: <#MockMagicCardLayout#>,
      legalities: <#MockMagicCardLegalities#>,
      name: <#String#>,
      collectorNumber: <#String#>,
      prices: <#MockMagicCardPrices#>,
      rarity: <#MockMagicCardRarity#>,
      relatedUris: <#[String : String]#>,
      releastedAt: <#String#>,
      setName: <#String#>, 
      set: <#String#>
    )
  }
}

