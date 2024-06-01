import Foundation

public protocol MagicCard: Equatable, Hashable, Identifiable, Sendable {
  /// The identifier of this card on Scryfall
  var id: UUID { get }
  
  /// The language that this specific printing was printed in
  func getLanguage() -> String
  
  /// An array of all the faces that a card has or nil if it's a single-faced card
  func getCardFaces() -> [any MagicCardFace]?
  
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
  
  /// The mana cost for this card
  func getManaCost() -> String?
  
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
  func getPurchaseUris() -> [String: String]?
  
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
  
  var isFlippable: Bool { get }
  var isRotatable: Bool { get }
  var isLandscape: Bool { get }
  var isPhyrexian: Bool { get }
}
