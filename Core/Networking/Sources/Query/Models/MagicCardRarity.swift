public enum MagicCardRarityValue: String, Equatable, Sendable, Hashable {
  case common, uncommon, rare, special, mythic, bonus, none
}

public protocol MagicCardRarity: Equatable, Sendable, Hashable {
  var value: MagicCardRarityValue { get }
}
