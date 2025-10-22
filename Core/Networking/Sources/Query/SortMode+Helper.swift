import ScryfallKit

extension SortMode: @retroactive Identifiable {
  public nonisolated var id: Self {
    return self
  }
  
  public var description: String {
    switch self {
    case .name:
      return String(localized: "Name")
    case .set:
      return String(localized: "Set")
    case .released:
      return String(localized: "Date")
    case .rarity:
      return String(localized: "Rarity")
    case .color:
      return String(localized: "Color")
    case .usd:
      return String(localized: "Price")
    case .tix:
      return String(localized: "TIX")
    case .eur:
      return String(localized: "EUR")
    case .cmc:
      return String(localized: "Mana Value")
    case .power:
      return String(localized: "Power")
    case .toughness:
      return String(localized: "Toughness")
    case .edhrec:
      return String(localized: "EDHREC Ranking")
    case .artist:
      return String(localized: "Artist")
    }
  }
}
