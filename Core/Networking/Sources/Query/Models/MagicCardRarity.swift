public enum MagicCardRarityValue: String, Equatable, Sendable, Hashable {
  case common, uncommon, rare, special, mythic, bonus, none
  
  public var colorNames: [String]? {
    switch self {
    case .common: return nil
    case .uncommon: return ["uncommonDark", "uncommonLight", "uncommonDark"]
    case .rare: return ["rareDark", "rareLight", "rareDark"]
    case .special: return nil
    case .mythic: return ["mythicDark", "mythicLight", "mythicDark"]
    case .bonus: return nil
    case .none: return nil
    }
  }
}

public protocol MagicCardRarity: Equatable, Sendable, Hashable {
  var value: MagicCardRarityValue { get }
}

