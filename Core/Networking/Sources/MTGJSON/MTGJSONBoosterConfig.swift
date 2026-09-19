import Foundation

/// One sealed product of a set: the sheets its packs draw from, and the layouts
/// its packs come out in.
struct MTGJSONBoosterConfig: Decodable {
  /// The product's full name, "Bloomburrow Play Booster".
  let name: String?
  /// Every way a pack of this product is put together. Each layout's `weight`
  /// out of `boostersTotalWeight` is how often a pack comes out that way.
  let boosters: [MTGJSONBoosterLayout]?
  let boostersTotalWeight: Double?
  let sheets: [String: MTGJSONBoosterSheet]
}
