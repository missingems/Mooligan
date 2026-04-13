import ScryfallKit
import Foundation


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
extension Card {
  /// Resolves the correct SVG icon URL, handling Scryfall's derivative set prefixes
  /// while routing true standalone promos to a generic fallback.
  public var resolvedIconURL: URL? {
    let code = self.set.lowercased()
    
    // 1. Explicit Overrides (Generic / Event Promos)
    // These don't map to any base set and will 404, so we force the shooting star.
    let genericPromoCodes: Set<String> = ["prm", "fnm", "jpromo", "sus", "sum"]
    if genericPromoCodes.contains(code) ||
        (code.hasPrefix("pw") && code.count == 4) || // e.g., pw26
        (code.hasPrefix("j") && code.count == 3 && code.dropFirst().allSatisfy(\.isWholeNumber)) { // e.g., j19
      return URL(string: "https://svgs.scryfall.io/sets/star.svg")
    }
    
    // 2. Strip Derivative Prefixes
    // If a code is 4+ letters and matches the specific setType modifier, extract the base set.
    if code.count >= 4 {
      if self.setType == .promo && code.hasPrefix("p") {
        let baseCode = String(code.dropFirst())
        return URL(string: "https://svgs.scryfall.io/sets/\(baseCode).svg")
      }
      if self.setType == .token && code.hasPrefix("t") {
        let baseCode = String(code.dropFirst())
        return URL(string: "https://svgs.scryfall.io/sets/\(baseCode).svg")
      }
      if self.setType == .alchemy && code.hasPrefix("y") {
        let baseCode = String(code.dropFirst())
        return URL(string: "https://svgs.scryfall.io/sets/\(baseCode).svg")
      }
      if self.setType == .minigame && code.hasPrefix("m") {
        let baseCode = String(code.dropFirst())
        return URL(string: "https://svgs.scryfall.io/sets/\(baseCode).svg")
      }
      if self.setType == .memorabilia && code.hasPrefix("a") { // Art series cards
        let baseCode = String(code.dropFirst())
        return URL(string: "https://svgs.scryfall.io/sets/\(baseCode).svg")
      }
    }
    
    // 3. Final Fallbacks
    switch self.setType {
    case .promo, .masterpiece, .vanguard, .treasureChest, .premiumDeck:
      // If it's a promo but failed the stripping rule above (e.g., a weird 3-letter promo set)
      return URL(string: "https://svgs.scryfall.io/sets/star.svg")
      
    default:
      // Standard expansions, core sets, masters, etc.
      return URL(string: "https://svgs.scryfall.io/sets/\(code).svg")
    }
  }
}
