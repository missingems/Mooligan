import ScryfallKit

extension Card.Rarity: MagicCardRarity {
  public var value: MagicCardRarityValue {
    MagicCardRarityValue(rawValue: rawValue) ?? .none
  }
}
