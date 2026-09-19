import Foundation

/// One product of a set, and the share of the set's opened packs it is taken to be.
///
/// Nobody publishes how many of each product are opened, so the shares are a guess, and kept
/// deliberately plain: the main booster (Play, or Draft and Set before them) about eight in ten
/// packs, the Collector Booster about one in ten, and the set's other packs the last one in ten.
/// Kinds the set does not sell drop out and the rest are scaled up to make the whole.
public struct PackShare: Equatable, Hashable, Sendable {
  public enum Kind: Int, Comparable, Sendable {
    case main
    case collector
    case other

    public static func < (lhs: Kind, rhs: Kind) -> Bool { lhs.rawValue < rhs.rawValue }
  }

  /// `"<set code>/<MTGJSON product key>"`, as in `"blb/play"`.
  public let id: String
  /// The product's name without its set's: "Play Booster".
  public let name: String
  public let kind: Kind
  /// The product's share of the set's opened packs, from 0 to 1.
  public let share: Double

  public init(id: String, name: String, kind: Kind, share: Double) {
    self.id = id
    self.name = name
    self.kind = kind
    self.share = share
  }

  /// The mix of `products`, product id to name, with each product's share of the opened packs.
  ///
  /// Promo packs, box toppers and the like are left out: they are not packs anyone opens in place of
  /// a booster, and counted in they would thin every card's odds for packs that never held it.
  static func mix(of products: [String: String]) -> [PackShare] {
    var packs: [(id: String, name: String, kind: Kind)] = []
    for (id, name) in products {
      if let kind = kind(of: id) { packs.append((id, name, kind)) }
    }
    packs.sort { lhs, rhs in lhs.kind == rhs.kind ? lhs.id < rhs.id : lhs.kind < rhs.kind }

    let weights: [Kind: Double] = [.main: 0.8, .collector: 0.1, .other: 0.1]
    var counts: [Kind: Int] = [:]
    for pack in packs { counts[pack.kind, default: 0] += 1 }
    let total = counts.keys.reduce(0.0) { $0 + (weights[$1] ?? 0) }
    guard total > 0 else { return [] }

    return packs.map { pack in
      let share = (weights[pack.kind] ?? 0) / total / Double(counts[pack.kind] ?? 1)
      return PackShare(id: pack.id, name: pack.name, kind: pack.kind, share: share)
    }
  }

  /// Which kind of pack a product is, from its MTGJSON key, or nil for one that is not a pack.
  static func kind(of id: String) -> Kind? {
    let key = String(id.split(separator: "/").last ?? "")
    if ["play", "draft", "set", "default"].contains(key) { return .main }
    if key == "collector" { return .collector }
    if ["promo", "prerelease", "topper", "scene"].contains(where: { key.contains($0) }) { return nil }
    return .other
  }
}
