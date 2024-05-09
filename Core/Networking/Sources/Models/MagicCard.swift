import Foundation

public protocol MagicCardRelated { }

public protocol MagicCard: Equatable, Hashable, Identifiable {
  /// The identifier of this card on Scryfall
  var id: UUID { get }
  
  /// The language that this specific printing was printed in
  var lang: String { get }
  
  /// An array of related cards (tokens, meld parts, etc) or nil if there are none
  var allParts: [any MagicCard]? { get }
  
  /// An array of all the faces that a card has or nil if it's a single-faced card
  var cardFaces: [any MagicCardFace]? { get }
  
  /// The converted mana cost of a card, now called the "mana value"
  /// - Note: Scryfall's documentation lists this as required but it's nil for reversible cards
  var manaValue: Double? { get }
  
  /// An array of colors representing this card's color identity.
  ///
  /// Color identity is used to determine what cards are legal in a Commander deck. See the [comprehensive rules](https://magic.wizards.com/en/rules) for more information
  var colorIdentity: [any MagicCardColor] { get }
  
  /// An array of the colors in this card’s color indicator or nil if it doesn't have one
  ///
  /// Color indicators are used to specify the color of a card that has no mana symbols
  var colorIndicator: [any MagicCardColor]? { get }
  
  /// An array of the colors in this card's mana cost
  var colors: [any MagicCardColor]? { get }
  
  /// An array of the keywords on this card (deathouch, first strike, etc)
  var keywords: [String] { get }
  
  /// This card's layout (normal, transform, split, etc)
  var layout: any MagicCardLayout { get }
  
  /// The formats that this card is legal in
  var legalities: any MagicCardLegalities { get }
  
  /// This card's starting loyalty counters if it's a planeswalker
  var loyalty: String? { get }
  
  /// The mana cost for this card.
  ///
  /// This value will be any empty string "" if the cost is absent. Remember that per the game rules, a missing mana cost and a mana cost of {0} are different values.
  var manaCost: String? { get }
  
  /// The name of this card
  ///
  /// If the card has multiple faces the names will be separated by a "//" such as "Wear // Tear"
  var name: String { get }
  
  /// The oracle text for this card
  var oracleText: String? { get }
  
  /// The power of this card if it's a creature
  var power: String? { get }
  
  /// The colors of mana that this card _could_ produce
  var producedMana: [any MagicCardColor]? { get }
  
  /// The toughness of this card if it's a creature
  var toughness: String? { get }
  
  /// This card's types, separated by a space
  /// - Note: Tokens don't have type lines
  var typeLine: String? { get }
  
  /// The name of the artist who illustrated this card
  var artist: String? { get }
  
  /// This card's collector number
  var collectorNumber: String { get }
  
  /// This card's flavor text if any
  var flavorText: String? { get }
  
  /// An object containing daily price information for this card
  var prices: any MagicCardPrices { get }
  
  /// The localized name printed on this card, if any.
  var printedName: String? { get }
  
  /// The localized text printed on this card, if any.
  var printedText: String? { get }
  
  /// The localized type line printed on this card, if any.
  var printedTypeLine: String? { get }
  
  /// A dictionary of URIs to this card’s listing on major marketplaces.
  var purchaseUris: [String: String]? { get }
  
  /// This card's rarity
  var rarity: any MagicCardRarity { get }
  
  /// A dictionary of links to other MTG resources
  var relatedUris: [String: String] { get }
  
  /// This card's release date
  var releasedAt: String { get }
  
  /// This card's full set name
  var setName: String { get }
  
  /// This card's set code
  var set: String { get }
  
  /// Get card art in normal quality
  func getImageURL() -> URL?
}
