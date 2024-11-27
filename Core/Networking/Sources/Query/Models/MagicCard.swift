import Foundation

public protocol MagicCard: Equatable, Hashable, Identifiable, Sendable {
  /// The identifier of this card on Scryfall
  var id: UUID { get }
  
  /// The language that this specific printing was printed in
  func getLanguage() -> String
  
  /// Return the face of a card base on the direction
  func getCardFace(for direction: MagicCardFaceDirection) -> any MagicCardFace
  
  /// The converted mana cost of a card, now called the "mana value"
  func getManaValue() -> Double?
  
  /// An array of colors representing this card's color identity
  func getColorIdentity() -> [any MagicCardColor]
  
  /// An array of the colors in this card’s color indicator or nil if it doesn't have one
  func getColorIndicator() -> [any MagicCardColor]?
  
  /// An array of the colors in this card's mana cost
  func getColors() -> [any MagicCardColor]?
  
  /// An array of the keywords on this card (deathouch, first strike, etc)
  func getKeywords() -> [String]
  
  /// This card's layout (normal, transform, split, etc)
  func getLayout() -> any MagicCardLayout
  
  /// The formats that this card is legal in
  func getLegalities() -> any MagicCardLegalities
  
  /// This card's starting loyalty counters if it's a planeswalker
  func getLoyalty() -> String?
  
  /// The name of this card
  func getName() -> String
  
  /// The oracle text for this card
  func getOracleText() -> String?
  
  /// The power of this card if it's a creature
  func getPower() -> String?
  
  /// The colors of mana that this card could produce
  func getProducedMana() -> [any MagicCardColor]?
  
  /// The toughness of this card if it's a creature
  func getToughness() -> String?
  
  /// This card's types, separated by a space
  func getTypeLine() -> String?
  
  /// The name of the artist who illustrated this card
  func getArtist() -> String?
  
  /// This card's collector number
  func getCollectorNumber() -> String
  
  /// This card's flavor text if any
  func getFlavorText() -> String?
  
  /// An object containing daily price information for this card
  func getPrices() -> any MagicCardPrices
  
  /// The localized name printed on this card, if any
  func getPrintedName() -> String?
  
  /// The localized text printed on this card, if any
  func getPrintedText() -> String?
  
  /// The localized type line printed on this card, if any
  func getPrintedTypeLine() -> String?
  
  /// A dictionary of URIs to this card’s listing on major marketplaces
  func getPurchaseUris() -> PurchaseVendor
  
  /// This card's rarity
  func getRarity() -> any MagicCardRarity
  
  /// A dictionary of links to other MTG resources
  func getRelatedUris() -> [String: String]
  
  /// This card's release date
  func getReleasedAt() -> String
  
  /// This card's full set name
  func getSetName() -> String
  
  /// This card's set code
  func getSet() -> String
  
  /// Get card art in normal quality
  func getImageURL() -> URL?
}

public extension MagicCard {
  var isTransformable: Bool {
    let layout = getLayout().value
    
    return (
      layout == .transform ||
      layout == .modalDfc ||
      layout == .reversibleCard ||
      layout == .doubleFacedToken
    )
  }
  
  var isFlippable: Bool {
    getLayout().value == .flip
  }
  
  var hasMultipleColumns: Bool {
    getLayout().value == .split || getLayout().value == .adventure
  }
  
  var isPhyrexian: Bool {
    getLanguage() == "ph"
  }
  
  var isLandscape: Bool {
    getLayout().value == .split || getLayout().value == .battle
  }
  
  func getDisplayManaCost(faceDirection: MagicCardFaceDirection) -> [String] {
    guard
      let pattern = try? Regex("\\{[^}]+\\}"),
      let manaCost = getCardFace(for: faceDirection).getManaCost()?
        .replacingOccurrences(of: "/", with: ":")
        .replacingOccurrences(of: "∞", with: "INFINITY")
    else {
      return []
    }
    
    return manaCost
      .matches(of: pattern)
      .compactMap { String(manaCost[$0.range]) }
  }
  
  func getDisplayName(faceDirection: MagicCardFaceDirection) -> String {
    let face = getCardFace(for: faceDirection)
    return isPhyrexian ? face.name : face.printedName ?? face.name
  }
  
  func getDisplayText(faceDirection: MagicCardFaceDirection) -> String? {
    let face = getCardFace(for: faceDirection)
    return isPhyrexian ? face.oracleText : face.printedText ?? face.oracleText
  }
  
  func getDisplayTypeline(faceDirection: MagicCardFaceDirection) -> String? {
    let face = getCardFace(for: faceDirection)
    return isPhyrexian ? face.typeLine : face.printedTypeLine ?? face.typeLine
  }
}
