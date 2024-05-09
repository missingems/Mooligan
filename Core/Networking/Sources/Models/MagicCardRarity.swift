public enum MagicCardRarityValue: String, Equatable, Sendable {
  case common, uncommon, rare, special, mythic, bonus, none
}

public protocol MagicCardRarity {
  var value: MagicCardRarityValue { get }
}
