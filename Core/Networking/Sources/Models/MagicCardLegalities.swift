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

public enum MagicCardLegality: Equatable, Sendable {
  /// This card is legal to be played in this format
  case legal
  /// This card is restricted in this format (players may only have one copy in their deck)
  case restricted
  /// This card has been banned in this format
  case banned
  /// This card is not legal in this format (ex: an uncommon is not legal in pauper)
  case notLegal
}

public protocol MagicCardLegalities {
  var value: [MagicCardLegalitiesValue] { get }
}
