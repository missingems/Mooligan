import Foundation
import ScryfallKit

public struct MockMagicCard<
    Face: MagicCardFace,
    Color: MagicCardColor,
    Layout: MagicCardLayout,
    Legalities: MagicCardLegalities,
    Prices: MagicCardPrices,
    Rarity: MagicCardRarity
>: MagicCard {
  public var id: UUID
  private var language: String
  private var cardFace: Face
  private var manaValue: Double?
  private var colorIdentity: [Color]
  private var colorIndicator: [Color]?
  private var colors: [Color]?
  private var keywords: [String]
  private var layout: Layout
  private var legalities: Legalities
  private var loyalty: String?
  private var name: String
  private var oracleText: String?
  private var power: String?
  private var producedMana: [Color]?
  private var toughness: String?
  private var typeline: String?
  private var artist: String?
  private var collectorNumber: String
  private var flavorText: String?
  private var prices: Prices
  private var printedName: String?
  private var printedText: String?
  private var printedTypeLine: String?
  private var purchaseUris: [String: String]?
  private var rarity: Rarity
  private var relatedUris: [String: String]
  private var releastedAt: String
  private var setName: String
  private var set: String
  private var imageURL: URL?
  
  public init(
    id: UUID,
    language: String,
    cardFace: Face,
    manaValue: Double? = nil,
    colorIdentity: [Color],
    colorIndicator: [Color]? = nil,
    colors: [Color]? = nil,
    keywords: [String],
    layout: Layout,
    legalities: Legalities,
    loyalty: String? = nil,
    name: String,
    oracleText: String? = nil,
    power: String? = nil,
    producedMana: [Color]? = nil,
    toughness: String? = nil,
    typeline: String? = nil,
    artist: String? = nil,
    collectorNumber: String,
    flavorText: String? = nil,
    prices: Prices,
    printedName: String? = nil,
    printedText: String? = nil,
    printedTypeLine: String? = nil,
    purchaseUris: [String : String]? = nil,
    rarity: Rarity,
    relatedUris: [String : String],
    releastedAt: String,
    setName: String,
    set: String,
    imageURL: URL? = nil
  ) {
    self.id = id
    self.language = language
    self.cardFace = cardFace
    self.manaValue = manaValue
    self.colorIdentity = colorIdentity
    self.colorIndicator = colorIndicator
    self.colors = colors
    self.keywords = keywords
    self.layout = layout
    self.legalities = legalities
    self.loyalty = loyalty
    self.name = name
    self.oracleText = oracleText
    self.power = power
    self.producedMana = producedMana
    self.toughness = toughness
    self.typeline = typeline
    self.artist = artist
    self.collectorNumber = collectorNumber
    self.flavorText = flavorText
    self.prices = prices
    self.printedName = printedName
    self.printedText = printedText
    self.printedTypeLine = printedTypeLine
    self.purchaseUris = purchaseUris
    self.rarity = rarity
    self.relatedUris = relatedUris
    self.releastedAt = releastedAt
    self.setName = setName
    self.set = set
    self.imageURL = imageURL
  }
  
  public mutating func setLanguage(_ language: String) -> Self {
    self.language = language
    return self
  }
  
  public mutating func setCardFace(_ cardFace: Face) -> Self {
    self.cardFace = cardFace
    return self
  }
  
  public mutating func setManaValue(_ manaValue: Double?) -> Self {
    self.manaValue = manaValue
    return self
  }
  
  public mutating func setColorIdentity(_ colorIdentity: [Color]) -> Self {
    self.colorIdentity = colorIdentity
    return self
  }
  
  public mutating func setColorIndicator(_ colorIndicator: [Color]?) -> Self {
    self.colorIndicator = colorIndicator
    return self
  }
  
  public mutating func setColors(_ colors: [Color]?) -> Self {
    self.colors = colors
    return self
  }
  
  public mutating func setKeywords(_ keywords: [String]) -> Self {
    self.keywords = keywords
    return self
  }
  
  public mutating func setLayout(_ layout: Layout) -> Self {
    self.layout = layout
    return self
  }
  
  public mutating func setLegalities(_ legalities: Legalities) -> Self {
    self.legalities = legalities
    return self
  }
  
  public mutating func setLoyalty(_ loyalty: String?) -> Self {
    self.loyalty = loyalty
    return self
  }
  
  public mutating func setName(_ name: String) -> Self {
    self.name = name
    return self
  }
  
  public mutating func setOracleText(_ oracleText: String?) -> Self {
    self.oracleText = oracleText
    return self
  }
  
  public mutating func setPower(_ power: String?) -> Self {
    self.power = power
    return self
  }
  
  public mutating func setProducedMana(_ producedMana: [Color]?) -> Self {
    self.producedMana = producedMana
    return self
  }
  
  public mutating func setToughness(_ toughness: String?) -> Self {
    self.toughness = toughness
    return self
  }
  
  public mutating func setTypeline(_ typeline: String?) -> Self {
    self.typeline = typeline
    return self
  }
  
  public mutating func setArtist(_ artist: String?) -> Self {
    self.artist = artist
    return self
  }
  
  public mutating func setCollectorNumber(_ collectorNumber: String) -> Self {
    self.collectorNumber = collectorNumber
    return self
  }
  
  public mutating func setFlavorText(_ flavorText: String?) -> Self {
    self.flavorText = flavorText
    return self
  }
  
  public mutating func setPrices(_ prices: Prices) -> Self {
    self.prices = prices
    return self
  }
  
  public mutating func setPrintedName(_ printedName: String?) -> Self {
    self.printedName = printedName
    return self
  }
  
  public mutating func setPrintedText(_ printedText: String?) -> Self {
    self.printedText = printedText
    return self
  }
  
  public mutating func setPrintedTypeLine(_ printedTypeLine: String?) -> Self {
    self.printedTypeLine = printedTypeLine
    return self
  }
  
  public mutating func setPurchaseUris(_ purchaseUris: [String: String]?) -> Self {
    self.purchaseUris = purchaseUris
    return self
  }
  
  public mutating func setRarity(_ rarity: Rarity) -> Self {
    self.rarity = rarity
    return self
  }
  
  public mutating func setRelatedUris(_ relatedUris: [String: String]) -> Self {
    self.relatedUris = relatedUris
    return self
  }
  
  public mutating func setReleasedAt(_ releasedAt: String) -> Self {
    self.releastedAt = releasedAt
    return self
  }
  
  public mutating func setSetName(_ setName: String) -> Self {
    self.setName = setName
    return self
  }
  
  public mutating func setSet(_ set: String) -> Self {
    self.set = set
    return self
  }
  
  public mutating func setImageURL(_ imageURL: URL?) -> Self {
    self.imageURL = imageURL
    return self
  }

  public func getLanguage() -> String { language }
  public func getCardFace(for direction: MagicCardFaceDirection) -> any MagicCardFace { cardFace }
  public func getManaValue() -> Double? { manaValue }
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
  public func getTypeLine() -> String? { typeline }
  public func getArtist() -> String? { artist }
  public func getCollectorNumber() -> String { collectorNumber }
  public func getFlavorText() -> String? { flavorText }
  public func getPrices() -> any MagicCardPrices { prices }
  public func getPrintedName() -> String? { printedName }
  public func getPrintedText() -> String? { printedText }
  public func getPrintedTypeLine() -> String? { printedTypeLine }
  public func getPurchaseUris() -> [String: String]? { purchaseUris }
  public func getRarity() -> any MagicCardRarity { rarity }
  public func getRelatedUris() -> [String: String] { relatedUris }
  public func getReleasedAt() -> String { releastedAt }
  public func getSetName() -> String { setName }
  public func getSet() -> String { set }
  public func getImageURL() -> URL? { imageURL }
}

public struct MockMagicCardLegalities: MagicCardLegalities, Hashable {
  public var value: [MagicCardLegalitiesValue]
}

public struct MockMagicCardRarity: MagicCardRarity {
  public var value: MagicCardRarityValue
}

public struct MockMagicCardColor: MagicCardColor {
  public var value: MagicCardColorValue
}

public struct MockMagicCardLayout: MagicCardLayout {
  public var value: MagicCardLayoutValue
}

public struct MockMagicCardFace<Color: MagicCardColor>: MagicCardFace {
  public var magicColorIndicator: [Color]?
  public var magicColors: [Color]?
  public var manaValue: Double?
  public var artist: String?
  public var flavorText: String?
  public var loyalty: String?
  public var name: String
  public var oracleText: String?
  public var power: String?
  public var printedName: String?
  public var printedText: String?
  public var printedTypeLine: String?
  public var toughness: String?
  public var typeLine: String?
  public func getImageURL() -> URL? { return nil }
  public func getManaCost() -> String? { return nil }
}

public struct MockMagicCardPrices: MagicCardPrices {
  public var tix: String?
  public var usd: String?
  public var usdFoil: String?
  public var eur: String?
}
