//
//  MockMagicCard.swift
//  QueryTests
//
//  Created by Jun on 10/5/24.
//

import Foundation

public struct MockMagicCard: MagicCard {
  public var id = UUID()
  
  public func getLanguage() -> String {
    return "en"
  }
  
  public func getCardFaces() -> [any Networking.MagicCardFace]? {
    return []
  }
  
  public func getManaValue() -> Double? {
    return 2
  }
  
  public func getColorIdentity() -> [any Networking.MagicCardColor] {
    return []
  }
  
  public func getColorIndicator() -> [any Networking.MagicCardColor]? {
    return []
  }
  
  public func getColors() -> [any Networking.MagicCardColor]? {
    return []
  }
  
  public func getKeywords() -> [String] {
    return ["Haste"]
  }
  
  public func getLayout() -> any Networking.MagicCardLayout {
    struct Layout: Networking.MagicCardLayout {
      var value: Networking.MagicCardLayoutValue
    }
    
    return Layout(value: .normal)
  }
  
  public func getLegalities() -> any Networking.MagicCardLegalities {
    struct Legalities: Networking.MagicCardLegalities {
      var value: [Networking.MagicCardLegalitiesValue]
    }
    
    return Legalities(value: [])
  }
  
  public func getLoyalty() -> String? { "3" }
  public func getManaCost() -> String? { "3" }
  public func getName() -> String { "Name" }
  public func getOracleText() -> String? { "Oracle" }
  public func getPower() -> String? { "Power" }
  public func getProducedMana() -> [any Networking.MagicCardColor]? { [] }
  public func getToughness() -> String? { "Toughness" }
  public func getTypeLine() -> String? { "Typeline "}
  public func getArtist() -> String? { "Artist" }
  public func getCollectorNumber() -> String { "442" }
  public func getFlavorText() -> String? { "Flavor" }
  
  public func getPrices() -> any Networking.MagicCardPrices {
    struct Price: Networking.MagicCardPrices {
      var tix: String?
      var usd: String?
      var usdFoil: String?
      var eur: String?
    }
    
    return Price()
  }
  
  public func getPrintedName() -> String? { "123" }
  public func getPrintedText() -> String? { "Text" }
  public func getPrintedTypeLine() -> String? { "TypeLine" }
  public func getPurchaseUris() -> [String: String]? { [:] }
  
  public func getRarity() -> any Networking.MagicCardRarity {
    struct Rarity: Networking.MagicCardRarity {
      var value: Networking.MagicCardRarityValue
    }
    
    return Rarity(value: .common)
  }
  
  public func getRelatedUris() -> [String: String] { [:] }
  public func getReleasedAt() -> String { "12-11-92" }
  public func getSetName() -> String { "123" }
  public func getSet() -> String { "123" }
  public func getImageURL() -> URL? { nil }
  
  public init(id: UUID = UUID()) {
    self.id = id
  }
}
