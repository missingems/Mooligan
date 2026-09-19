import Foundation

/// How rarely one printing comes out of the sealed products it is printed in.
public struct CardPullOdds: Equatable, Hashable, Sendable {
  /// Every product that can hold the card, the one most people open first.
  public let products: [ProductPullOdds]
  /// The packs of its set, each with the share of the opened packs it is taken to be: what the
  /// estimate is worked out over.
  public let mix: [PackShare]

  /// Nil when no product holds the card, so a value always has something to show.
  ///
  /// `setProducts` is every product of the card's set, id to name, including those that never hold
  /// the card: a pack that cannot hold it still counts against the estimate. Without them the
  /// estimate is worked out over the card's own products.
  ///
  /// Products are listed most opened first: a Play Booster, or before those a Draft Booster, then a
  /// Set and a Collector Booster, then the rest by how often they give the card up.
  public init?(products: [ProductPullOdds], setProducts: [String: String] = [:]) {
    guard products.isEmpty == false else { return nil }

    func rank(_ product: ProductPullOdds) -> Int {
      ["play", "draft", "default", "set", "collector"].firstIndex(of: product.productKey) ?? 5
    }

    self.products = products.sorted { lhs, rhs in
      rank(lhs) == rank(rhs) ? lhs.chance > rhs.chance : rank(lhs) < rank(rhs)
    }
    mix = PackShare.mix(of: setProducts.isEmpty
      ? Dictionary(products.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
      : setProducts
    )
  }

  public var headline: ProductPullOdds { products[0] }

  /// The chance that any one pack of the set holds this printing, whichever product the pack is: each
  /// product's own chance, weighted by its share of the packs opened.
  ///
  /// A printing that only turns up in something outside the mix, a prerelease or a bundle's promo,
  /// has no share to weigh; it is quoted at the best of its own products instead, and
  /// `isEstimated` is false so it is not presented as a figure for the set's packs.
  public var estimate: Double {
    isEstimated ? weighed : products.map(\.chance).max() ?? 0
  }

  /// Whether `estimate` is worked out across the set's packs, rather than taken from a product
  /// outside them.
  public var isEstimated: Bool {
    weighed > 0
  }

  private var weighed: Double {
    mix.reduce(0) { total, pack in
      total + pack.share * (products.first { $0.id == pack.id }?.chance ?? 0)
    }
  }

  /// The estimate as the "n" of "1 in n packs".
  public var estimatePacks: Int? {
    ProductPullOdds.packs(for: estimate)
  }
}
