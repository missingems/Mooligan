public enum MagicCardLegalitiesValue: Equatable, Sendable, Hashable {
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
  
  public var value: String {
    switch self {
    case 
      let .standard(magicCardLegality),
      let .historic(magicCardLegality),
      let .pioneer(magicCardLegality),
      let .modern(magicCardLegality),
      let .legacy(magicCardLegality),
      let .pauper(magicCardLegality),
      let .vintage(magicCardLegality),
      let .penny(magicCardLegality),
      let .commander(magicCardLegality),
      let .brawl(magicCardLegality):
      magicCardLegality.label
    }
  }
  
  public var backgroundColorName: String {
    switch self {
    case
      let .standard(magicCardLegality),
      let .historic(magicCardLegality),
      let .pioneer(magicCardLegality),
      let .modern(magicCardLegality),
      let .legacy(magicCardLegality),
      let .pauper(magicCardLegality),
      let .vintage(magicCardLegality),
      let .penny(magicCardLegality),
      let .commander(magicCardLegality),
      let .brawl(magicCardLegality):
      magicCardLegality.backgroundColorName
    }
  }
  
  public var title: String {
    switch self {
    case .standard: String(localized: "Standard")
    case .historic: String(localized: "Historic")
    case .pioneer: String(localized: "Pioneer")
    case .modern: String(localized: "Modern")
    case .legacy: String(localized: "Legacy")
    case .pauper: String(localized: "Pauper")
    case .vintage: String(localized: "Vintage")
    case .penny: String(localized: "Penny")
    case .commander: String(localized: "Commander")
    case .brawl: String(localized: "Brawl")
    }
  }
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
    case .notLegal: String(localized: "Not Legal")
    default: String(localized: "\(rawValue.capitalized)")
    }
  }
  
  public var backgroundColorName: String {
    switch self {
    case .banned: "banned"
    case .legal: "legal"
    case .restricted: "restricted"
    case .notLegal: "notLegal"
    }
  }
}
