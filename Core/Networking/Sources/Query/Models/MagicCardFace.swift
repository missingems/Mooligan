import Foundation

public protocol MagicCardFace {
  /// The converted mana cost of a card, now called the "mana value"
  var manaValue: Double? { get }
  
  /// The name of the artist who illustrated this card
  var artist: String? { get }
  
  /// An array of the colors in this card’s color indicator or nil if it doesn't have one
  ///
  /// Color indicators are used to specify the color of a card that has no mana symbols
  var magicColorIndicator: [any MagicCardColor]? { get }
  
  /// An array of the colors in this card's mana cost
  var magicColors: [any MagicCardColor]? { get }
  
  /// This card's flavor text if any
  var flavorText: String? { get }
  
  /// This card's starting loyalty counters if it's a planeswalker
  var loyalty: String? { get }
  
  /// The mana cost for this card.
  ///
  /// This value will be any empty string "" if the cost is absent. Remember that per the game rules, a missing mana cost and a mana cost of {0} are different values.
  var manaCost: String { get }
  
  /// The name of this card
  ///
  /// If the card has multiple faces the names will be separated by a "//" such as "Wear // Tear"
  var name: String { get }
  
  /// The oracle text for this card
  var oracleText: String? { get }
  
  /// The power of this card if it's a creature
  var power: String? { get }
  
  /// The localized name printed on this card, if any.
  var printedName: String? { get }
  
  /// The localized text printed on this card, if any.
  var printedText: String? { get }
  
  /// The localized type line printed on this card, if any.
  var printedTypeLine: String? { get }
  
  /// The toughness of this card if it's a creature
  var toughness: String? { get }
  
  /// This card's types, separated by a space
  /// - Note: Tokens don't have type lines
  var typeLine: String? { get }
  
  /// Get card art in normal quality
  func getImageURL() -> URL?
}
