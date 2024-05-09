public enum MagicCardLegalitiesValue: Codable, Hashable, Sendable {
  public let standard: Legality?
  public let historic: Legality?
  public let pioneer: Legality?
  public let modern: Legality?
  public let legacy: Legality?
  public let pauper: Legality?
  public let vintage: Legality?
  public let penny: Legality?
  public let commander: Legality?
  public let brawl: Legality?
  
  public init(standard: Legality?,
              historic: Legality?,
              pioneer: Legality?,
              modern: Legality?,
              legacy: Legality?,
              pauper: Legality?,
              vintage: Legality?,
              penny: Legality?,
              commander: Legality?,
              brawl: Legality?) {
    self.standard = standard
    self.historic = historic
    self.pioneer = pioneer
    self.modern = modern
    self.legacy = legacy
    self.pauper = pauper
    self.vintage = vintage
    self.penny = penny
    self.commander = commander
    self.brawl = brawl
  }
}

public enum MagicCardLegality {
  /// This card is legal to be played in this format
  case legal
  /// This card is restricted in this format (players may only have one copy in their deck)
  case restricted
  /// This card has been banned in this format
  case banned
  /// This card is not legal in this format (ex: an uncommon is not legal in pauper)
  case notLegal
  
  public var label: String {
    switch self {
    case .notLegal:
      return "Not Legal"
    default:
      return rawValue.capitalized
    }
  }
}

protocol MagicCardLegalities {
  var value: [MagicCardLegalities] { get }
}
