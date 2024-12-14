import Foundation
import ScryfallKit

extension Card: MagicCard {
  public func getOracleID() -> String? { oracleId }
  public func getLanguage() -> String { lang }
  public func getManaValue() -> Double? { cmc }
  public func getColorIdentity() -> [any MagicCardColor] { colorIdentity }
  public func getColorIndicator() -> [any MagicCardColor]? { colorIndicator }
  public func getColors() -> [any MagicCardColor]? { colors }
  public func getKeywords() -> [String] { keywords }
  public func getLayout() -> any MagicCardLayout { layout }
  public func getLegalities() -> any MagicCardLegalities { legalities }
  public func getLoyalty() -> String? { loyalty }
  public func getName() -> String { name }
  public func getOracleText() -> String? { oracleText }
  public func getPower() -> String? { power }
  public func getProducedMana() -> [any MagicCardColor]? { producedMana }
  public func getToughness() -> String? { toughness }
  public func getTypeLine() -> String? { typeLine }
  public func getArtist() -> String? { artist }
  public func getCollectorNumber() -> String { collectorNumber }
  public func getFlavorText() -> String? { flavorText }
  public func getPrices() -> any MagicCardPrices { prices }
  public func getPrintedName() -> String? { printedName }
  public func getPrintedText() -> String? { printedText }
  public func getPrintedTypeLine() -> String? { printedTypeLine }
  public func getPurchaseUris() -> PurchaseVendor {
    PurchaseVendor(purchaseURIs: purchaseUris)
  }
  public func getRarity() -> any MagicCardRarity { rarity }
  public func getRelatedUris() -> [String: String] { relatedUris }
  public func getReleasedAt() -> String { releasedAt }
  public func getSetName() -> String { setName }
  public func getSet() -> String { self.set }
  
  public func getMultiverseIds() -> [Int]? {
    return self.multiverseIds
  }
}

extension Card: MagicCardFace {
  public var manaValue: Double? {
    return getManaValue()
  }
  
  public var magicColorIndicator: [Card.Color]? {
    return colorIdentity
  }
  
  public var magicColors: [Card.Color]? {
    return colorIdentity
  }
  
  public func getManaCost() -> String? {
    return manaCost
  }
}

extension Card {
  public func getImageURL() -> URL? {
    return getImageURL(type: .normal)
  }
  
  public func getArtCroppedImageURL() -> URL? {
    return getImageURL(type: .artCrop)
  }
  
  public func getCardFace(for direction: MagicCardFaceDirection) -> any MagicCardFace {
    return switch direction {
    case .front:
      cardFaces?.first ?? self
      
    case .back:
      cardFaces?.last ?? self
    }
  }
  
  public func getGathererURLString() -> String? {
    if let id = getMultiverseIds()?.first {
      return "https://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=\(id)"
    } else {
      return nil
    }
  }
}
