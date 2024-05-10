public enum MagicCardLegalitiesValue: Equatable, Sendable {
  case standard(MagicCardLegality)
  case historic(MagicCardLegality)
  case pioneer(MagicCardLegality)
  case modern(MagicCardLegality)
  case legacy(MagicCardLegality)
  case pauper(MagicCardLegality)
  case vintage(MagicCardLegality)
  case penny(MagicCardLegality)
  case commander(MagicCardLegality)
  case brawl(MagicCardLegality)
}

public enum MagicCardLegality: String, Equatable, Sendable {
  /// This card is legal to be played in this format
  case legal
  /// This card is restricted in this format (players may only have one copy in their deck)
  case restricted
  /// This card has been banned in this format
  case banned
  /// This card is not legal in this format (ex: an uncommon is not legal in pauper)
  case notLegal = "not_legal"
  
  public var label: String {
    switch self {
    case .notLegal:
      return "Not Legal"
    default:
      return rawValue.capitalized
    }
  }
}

public protocol MagicCardLegalities {
  var value: [MagicCardLegalitiesValue] { get }
}
