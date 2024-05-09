public enum MagicCardRarityValue {
  case common, uncommon, rare, special, mythic, bonus
}

public protocol MagicCardRarity {
  var value: MagicCardRarityValue { get }
}
