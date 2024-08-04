import Foundation.NSURL

public final class MagicCardBuilder<Color: MagicCardColor> {
  private var id: UUID = UUID()
  private var language: String = ""
  private var cardFaces: [MockMagicCardFace<Color>] = []
  private var manaValue: Double? = nil
  private var manaCost: String? = nil
  private var colorIdentity: [Color] = []
  private var colorIndicator: [Color]? = nil
  private var colors: [Color]? = nil
  private var keywords: [String] = []
  private var layout: MockMagicCardLayout = MockMagicCardLayout()
  private var legalities: MockMagicCardLegalities = MockMagicCardLegalities()
  private var loyalty: String? = nil
  private var name: String = ""
  private var oracleText: String? = nil
  private var power: String? = nil
  private var producedMana: [Color]? = nil
  private var toughness: String? = nil
  private var typeLine: String? = nil
  private var artist: String? = nil
  private var collectorNumber: String = ""
  private var flavorText: String? = nil
  private var prices: MockMagicCardPrices = MockMagicCardPrices()
  private var printedName: String? = nil
  private var printedText: String? = nil
  private var printedTypeLine: String? = nil
  private var purchaseUris: [String: String]? = nil
  private var rarity: MockMagicCardRarity = MockMagicCardRarity()
  private var relatedUris: [String: String] = [:]
  private var releasedAt: String = ""
  private var setName: String = ""
  private var set: String = ""
  private var imageURL: URL? = nil
  
  public init() {}
  
  public func with(language: String) -> Self {
    self.language = language
    return self
  }
  
  public func with(cardFaces: [MockMagicCardFace<Color>]) -> Self {
    self.cardFaces = cardFaces
    return self
  }
  
  public func with(manaValue: Double?) -> Self {
    self.manaValue = manaValue
    return self
  }
  
  public func with(manaCost: String?) -> Self {
    self.manaCost = manaCost
    return self
  }
  
  public func with(colorIdentity: [Color]) -> Self {
    self.colorIdentity = colorIdentity
    return self
  }
  
  public func with(colorIndicator: [Color]?) -> Self {
    self.colorIndicator = colorIndicator
    return self
  }
  
  public func with(colors: [Color]?) -> Self {
    self.colors = colors
    return self
  }
  
  public func with(keywords: [String]) -> Self {
    self.keywords = keywords
    return self
  }
  
  public func with(layout: MockMagicCardLayout) -> Self {
    self.layout = layout
    return self
  }
  
  public func with(legalities: MockMagicCardLegalities) -> Self {
    self.legalities = legalities
    return self
  }
  
  public func with(loyalty: String?) -> Self {
    self.loyalty = loyalty
    return self
  }
  
  public func with(name: String) -> Self {
    self.name = name
    return self
  }
  
  public func with(oracleText: String?) -> Self {
    self.oracleText = oracleText
    return self
  }
  
  public func with(power: String?) -> Self {
    self.power = power
    return self
  }
  
  public func with(producedMana: [Color]?) -> Self {
    self.producedMana = producedMana
    return self
  }
  
  public func with(toughness: String?) -> Self {
    self.toughness = toughness
    return self
  }
  
  public func with(typeline: String?) -> Self {
    self.typeLine = typeline
    return self
  }
  
  public func with(artist: String?) -> Self {
    self.artist = artist
    return self
  }
  
  public func with(collectorNumber: String) -> Self {
    self.collectorNumber = collectorNumber
    return self
  }
  
  public func with(flavorText: String?) -> Self {
    self.flavorText = flavorText
    return self
  }
  
  public func with(prices: MockMagicCardPrices) -> Self {
    self.prices = prices
    return self
  }
  
  public func with(printedName: String?) -> Self {
    self.printedName = printedName
    return self
  }
  
  public func with(printedText: String?) -> Self {
    self.printedText = printedText
    return self
  }
  
  public func with(printedTypeLine: String?) -> Self {
    self.printedTypeLine = printedTypeLine
    return self
  }
  
  public func with(purchaseUris: [String: String]?) -> Self {
    self.purchaseUris = purchaseUris
    return self
  }
  
  public func with(rarity: MockMagicCardRarity) -> Self {
    self.rarity = rarity
    return self
  }
  
  public func with(relatedUris: [String: String]) -> Self {
    self.relatedUris = relatedUris
    return self
  }
  
  public func with(releasedAt: String) -> Self {
    self.releasedAt = releasedAt
    return self
  }
  
  public func with(setName: String) -> Self {
    self.setName = setName
    return self
  }
  
  public func with(set: String) -> Self {
    self.set = set
    return self
  }
  
  public func with(imageURL: URL?) -> Self {
    self.imageURL = imageURL
    return self
  }
  
  public func build() -> MockMagicCard<Color> {
    MockMagicCard(
      id: id,
      language: language,
      cardFaces: cardFaces,
      manaValue: manaValue,
      manaCost: manaCost,
      colorIdentity: colorIdentity,
      colorIndicator: colorIndicator,
      colors: colors,
      keywords: keywords,
      layout: layout,
      legalities: legalities,
      loyalty: loyalty,
      name: name,
      oracleText: oracleText,
      power: power,
      producedMana: producedMana,
      toughness: toughness,
      typeline: typeLine,
      artist: artist,
      collectorNumber: collectorNumber,
      flavorText: flavorText,
      prices: prices,
      printedName: printedName,
      printedText: printedText,
      printedTypeLine: printedTypeLine,
      purchaseUris: purchaseUris,
      rarity: rarity,
      relatedUris: relatedUris,
      releastedAt: releasedAt,
      setName: setName,
      set: set,
      imageURL: imageURL
    )
  }
}
