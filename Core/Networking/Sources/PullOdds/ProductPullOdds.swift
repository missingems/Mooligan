import Foundation

/// The chance of opening one printing in one sealed product.
public struct ProductPullOdds: Equatable, Hashable, Sendable, Codable, Identifiable {
  /// `"<set code>/<MTGJSON product key>"`, as in `"blb/play"`.
  public let id: String
  /// The product's name without its set's: "Play Booster".
  public let name: String
  /// The set the product belongs to. Not always the card's own: a commander
  /// deck's card is opened in its parent set's Collector Booster.
  public let setName: String
  /// Chance that one pack holds at least one copy, in either finish.
  public let chance: Double
  public let foilChance: Double
  public let nonFoilChance: Double

  public init(
    id: String,
    name: String,
    setName: String,
    chance: Double,
    foilChance: Double,
    nonFoilChance: Double
  ) {
    self.id = id
    self.name = name
    self.setName = setName
    self.chance = chance
    self.foilChance = foilChance
    self.nonFoilChance = nonFoilChance
  }

  /// The "n" of "1 in n packs", which is how pull rates are always quoted.
  public var packs: Int? { Self.packs(for: chance) }
  public var foilPacks: Int? { Self.packs(for: foilChance) }
  public var nonFoilPacks: Int? { Self.packs(for: nonFoilChance) }

  /// MTGJSON's key for the product, "play" or "collector".
  public var productKey: String {
    String(id.split(separator: "/").last ?? "")
  }

  static func packs(for chance: Double) -> Int? {
    guard chance > 0 else { return nil }
    return max(1, Int((1 / chance).rounded()))
  }
}
