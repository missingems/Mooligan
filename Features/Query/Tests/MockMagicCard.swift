//
//  MockMagicCard.swift
//  QueryTests
//
//  Created by Jun on 10/5/24.
//

import Foundation
import Networking

struct MockMagicCard: MagicCard {
  var id = UUID()
  
  func getLanguage() -> String {
    return "en"
  }
  
  func getCardFaces() -> [any Networking.MagicCardFace]? {
    return []
  }
  
  func getManaValue() -> Double? {
    return 2
  }
  
  func getColorIdentity() -> [any Networking.MagicCardColor] {
    return []
  }
  
  func getColorIndicator() -> [any Networking.MagicCardColor]? {
    return []
  }
  
  func getColors() -> [any Networking.MagicCardColor]? {
    return []
  }
  
  func getKeywords() -> [String] {
    return ["Haste"]
  }
  
  func getLayout() -> any Networking.MagicCardLayout {
    struct Layout: Networking.MagicCardLayout {
      var value: Networking.MagicCardLayoutValue
    }
    
    return Layout(value: .normal)
  }
  
  func getLegalities() -> any Networking.MagicCardLegalities {
    struct Legalities: Networking.MagicCardLegalities {
      var value: [Networking.MagicCardLegalitiesValue]
    }
    
    return Legalities(value: [])
  }
  
  func getLoyalty() -> String? { "3" }
  func getManaCost() -> String? { "3" }
  func getName() -> String { "Name" }
  func getOracleText() -> String? { "Oracle" }
  func getPower() -> String? { "Power" }
  func getProducedMana() -> [any Networking.MagicCardColor]? { [] }
  func getToughness() -> String? { "Toughness" }
  func getTypeLine() -> String? { "Typeline "}
  func getArtist() -> String? { "Artist" }
  func getCollectorNumber() -> String { "442" }
  func getFlavorText() -> String? { "Flavor" }
  
  func getPrices() -> any Networking.MagicCardPrices {
    struct Price: Networking.MagicCardPrices {
      var tix: String?
      var usd: String?
      var usdFoil: String?
      var eur: String?
    }
    
    return Price()
  }
  
  func getPrintedName() -> String? { "123" }
  func getPrintedText() -> String? { "Text" }
  func getPrintedTypeLine() -> String? { "TypeLine" }
  func getPurchaseUris() -> [String: String]? { [:] }
  
  func getRarity() -> any Networking.MagicCardRarity {
    struct Rarity: Networking.MagicCardRarity {
      var value: Networking.MagicCardRarityValue
    }
    
    return Rarity(value: .common)
  }
  
  func getRelatedUris() -> [String: String] { [:] }
  func getReleasedAt() -> String { "12-11-92" }
  func getSetName() -> String { "123" }
  func getSet() -> String { "123" }
  func getImageURL() -> URL? { nil }
}
