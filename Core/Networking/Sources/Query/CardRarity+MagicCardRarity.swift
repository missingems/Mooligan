import ScryfallKit

extension Card.Rarity {
  public var colorNames: [String]? {
    switch self {
    case .common: return nil
    case .uncommon: return ["uncommonDark", "uncommonLight", "uncommonDark"]
    case .rare: return ["rareDark", "rareLight", "rareDark"]
    case .special: return nil
    case .mythic: return ["mythicDark", "mythicLight", "mythicDark"]
    case .bonus: return nil
    }
  }
}
