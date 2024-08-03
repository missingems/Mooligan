import Foundation
import ScryfallKit

public struct MockMagicCard<Color: MagicCardColor>: MagicCard {
  public var id: UUID
  private var language: String
  private var cardFace: MockMagicCardFace<Color>
  private var manaValue: Double?
  private var colorIdentity: [Color]
  private var colorIndicator: [Color]?
  private var colors: [Color]?
  private var keywords: [String]
  private var layout: MockMagicCardLayout
  private var legalities: MockMagicCardLegalities
  private var loyalty: String?
  private var name: String
  private var oracleText: String?
  private var power: String?
  private var producedMana: [Color]?
  private var toughness: String?
  private var typeLine: String?
  private var artist: String?
  private var collectorNumber: String
  private var flavorText: String?
  private var prices: MockMagicCardPrices
  private var printedName: String?
  private var printedText: String?
  private var printedTypeLine: String?
  private var purchaseUris: [String: String]?
  private var rarity: MockMagicCardRarity
  private var relatedUris: [String: String]
  private var releastedAt: String
  private var setName: String
  private var set: String
  private var imageURL: URL?
  
  public init(
    id: UUID = UUID(),
    language: String = "",
    cardFace: MockMagicCardFace<Color> = MockMagicCardFace<Color>(),
    manaValue: Double? = nil,
    colorIdentity: [Color] = [],
    colorIndicator: [Color]? = nil,
    colors: [Color]? = nil,
    keywords: [String] = [],
    layout: MockMagicCardLayout = MockMagicCardLayout(),
    legalities: MockMagicCardLegalities = MockMagicCardLegalities(),
    loyalty: String? = nil,
    name: String = "",
    oracleText: String? = nil,
    power: String? = nil,
    producedMana: [Color]? = nil,
    toughness: String? = nil,
    typeline: String? = nil,
    artist: String? = nil,
    collectorNumber: String = "",
    flavorText: String? = nil,
    prices: MockMagicCardPrices = MockMagicCardPrices(),
    printedName: String? = nil,
    printedText: String? = nil,
    printedTypeLine: String? = nil,
    purchaseUris: [String : String]? = nil,
    rarity: MockMagicCardRarity = MockMagicCardRarity(),
    relatedUris: [String: String] = [:],
    releastedAt: String = "",
    setName: String = "",
    set: String = "",
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
    self.typeLine = typeline
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
  public func getTypeLine() -> String? { typeLine }
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
  
  public init(value: [MagicCardLegalitiesValue] = []) {
    self.value = value
  }
}

public struct MockMagicCardRarity: MagicCardRarity {
  public var value: MagicCardRarityValue
  
  public init(value: MagicCardRarityValue = .common) {
    self.value = value
  }
}

public struct MockMagicCardColor: MagicCardColor {
  public var value: MagicCardColorValue
  
  public init(value: MagicCardColorValue = .none) {
    self.value = value
  }
}

public struct MockMagicCardLayout: MagicCardLayout {
  public var value: MagicCardLayoutValue
  
  public init(value: MagicCardLayoutValue = .normal) {
    self.value = value
  }
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
  
  public init(
    magicColorIndicator: [Color]? = nil,
    magicColors: [Color]? = nil,
    manaValue: Double? = nil,
    artist: String? = nil,
    flavorText: String? = nil,
    loyalty: String? = nil,
    name: String = "",
    oracleText: String? = nil,
    power: String? = nil,
    printedName: String? = nil,
    printedText: String? = nil,
    printedTypeLine: String? = nil,
    toughness: String? = nil,
    typeLine: String? = nil
  ) {
    self.magicColorIndicator = magicColorIndicator
    self.magicColors = magicColors
    self.manaValue = manaValue
    self.artist = artist
    self.flavorText = flavorText
    self.loyalty = loyalty
    self.name = name
    self.oracleText = oracleText
    self.power = power
    self.printedName = printedName
    self.printedText = printedText
    self.printedTypeLine = printedTypeLine
    self.toughness = toughness
    self.typeLine = typeLine
  }
  
  public mutating func setMagicColorIndicator(_ colorIndicators: [Color]) -> Self {
    self.magicColorIndicator = colorIndicators
    return self
  }

  public mutating func setMagicColors(_ colors: [Color]) -> Self {
    self.magicColors = colors
    return self
  }
  
  public mutating func setManaValue(_ manaValue: Double) -> Self {
    self.manaValue = manaValue
    return self
  }
  
  public mutating func setArtist(_ artistName: String) -> Self {
    self.artist = artistName
    return self
  }
  
  public mutating func setFlavorTest(_ flavorText: String) -> Self {
    self.flavorText = flavorText
    return self
  }
  
  public mutating func setLoyalty(_ loyalty: String) -> Self {
    self.loyalty = loyalty
    return self
  }
  
  public mutating func setName(_ name: String) -> Self {
    self.name = name
    return self
  }
  
  public mutating func setOracleText(_ text: String) -> Self {
    self.oracleText = text
    return self
  }
  
  public mutating func setPower(_ power: String) -> Self {
    self.power = power
    return self
  }
  
  public mutating func setPrintedName(_ name: String) -> Self {
    self.printedName = name
    return self
  }
  
  public mutating func setPrintedText(_ text: String) -> Self {
    self.printedText = text
    return self
  }
  
  public mutating func setPrintedTypeLine(_ typeLine: String) -> Self {
    self.printedTypeLine = typeLine
    return self
  }
  
  public mutating func setToughness(_ toughness: String) -> Self {
    self.toughness = toughness
    return self
  }
  
  public mutating func setTypeLine(_ typeLine: String) -> Self {
    self.typeLine = typeLine
    return self
  }
}

public struct MockMagicCardPrices: MagicCardPrices {
  public var tix: String?
  public var usd: String?
  public var usdFoil: String?
  public var eur: String?
  
  public init(
    tix: String? = nil,
    usd: String? = nil,
    usdFoil: String? = nil,
    eur: String? = nil
  ) {
    self.tix = tix
    self.usd = usd
    self.usdFoil = usdFoil
    self.eur = eur
  }
}
