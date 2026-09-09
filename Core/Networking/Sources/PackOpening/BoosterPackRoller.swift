import Foundation
import ScryfallKit

/// Every printing in a set that a booster is allowed to contain, bucketed by
/// the rarity the roller draws from.
public struct BoosterCardPool: Equatable, Sendable {
  public var commons: [Card]
  public var uncommons: [Card]
  public var rares: [Card]
  public var mythics: [Card]
  public var lands: [Card]

  public init(
    commons: [Card] = [],
    uncommons: [Card] = [],
    rares: [Card] = [],
    mythics: [Card] = [],
    lands: [Card] = []
  ) {
    self.commons = commons
    self.uncommons = uncommons
    self.rares = rares
    self.mythics = mythics
    self.lands = lands
  }

  /// A set with no commons or no rares can't produce a recognisable booster —
  /// the clients treat this as "fall through to the next pool source".
  public var isUsable: Bool {
    commons.isEmpty == false && (rares.isEmpty == false || mythics.isEmpty == false)
  }

  public var cardCount: Int {
    commons.count + uncommons.count + rares.count + mythics.count + lands.count
  }
}

// MARK: - Rolling

public enum BoosterPackRoller {
  /// Fills every slot of `kind` from `pool`.
  ///
  /// `odds` supplies the mythic rate and the two wildcard rarity tables —
  /// `BoosterPackOdds.fallback` if the caller has nothing better, real per-set
  /// numbers from `MTGJSONBoosterOddsSource` otherwise.
  ///
  /// Draws without replacement while the pool allows it, so a 14-card pack from
  /// a healthy set never shows you the same common twice; once a bucket is
  /// exhausted it starts repeating rather than returning a short pack.
  public static func roll(
    kind: BoosterPackKind,
    from pool: BoosterCardPool,
    odds: BoosterPackOdds = .fallback,
    using generator: inout some RandomNumberGenerator
  ) -> [PulledCard] {
    var remaining = pool

    return kind.slots.compactMap { slot in
      let isFoil = Double.random(in: 0..<1, using: &generator) < slot.foilChance

      guard
        let card = draw(slot: slot.kind, from: &remaining, fallback: pool, odds: odds, using: &generator)
      else {
        return nil
      }

      return PulledCard(card: card, slot: slot.kind, isFoil: isFoil)
    }
  }

  private static func draw(
    slot: PackSlotKind,
    from remaining: inout BoosterCardPool,
    fallback: BoosterCardPool,
    odds: BoosterPackOdds,
    using generator: inout some RandomNumberGenerator
  ) -> Card? {
    let rarity: Card.Rarity = switch slot {
    case .common: .common
    case .uncommon: .uncommon
    case .land: .common
    case .rareOrMythic:
      Double.random(in: 0..<1, using: &generator) < odds.mythicChance ? .mythic : .rare
    case .wildcard:
      weightedRarity(odds.wildcardWeights, using: &generator)
    case .foilWildcard:
      weightedRarity(odds.foilWildcardWeights, using: &generator)
    }

    // The land slot has its own bucket and quietly falls back to commons for
    // sets that print no basics.
    if slot == .land, let card = take(from: &remaining.lands, fallback: fallback.lands, using: &generator) {
      return card
    }

    if let card = take(rarity: rarity, from: &remaining, fallback: fallback, using: &generator) {
      return card
    }

    // Rarity unavailable in this set (many supplemental sets print no mythics):
    // step down until something is there.
    for downgrade in downgrades(from: rarity) {
      if let card = take(rarity: downgrade, from: &remaining, fallback: fallback, using: &generator) {
        return card
      }
    }

    return nil
  }

  private static func downgrades(from rarity: Card.Rarity) -> [Card.Rarity] {
    switch rarity {
    case .mythic: [.rare, .uncommon, .common]
    case .rare: [.mythic, .uncommon, .common]
    case .uncommon: [.common, .rare]
    default: [.uncommon, .rare]
    }
  }

  private static func take(
    rarity: Card.Rarity,
    from remaining: inout BoosterCardPool,
    fallback: BoosterCardPool,
    using generator: inout some RandomNumberGenerator
  ) -> Card? {
    switch rarity {
    case .common: take(from: &remaining.commons, fallback: fallback.commons, using: &generator)
    case .uncommon: take(from: &remaining.uncommons, fallback: fallback.uncommons, using: &generator)
    case .rare: take(from: &remaining.rares, fallback: fallback.rares, using: &generator)
    case .mythic: take(from: &remaining.mythics, fallback: fallback.mythics, using: &generator)
    case .special, .bonus: nil
    }
  }

  /// Removes and returns a random element. When the bucket has run dry it draws
  /// (with replacement) from the untouched `fallback` copy instead.
  private static func take(
    from bucket: inout [Card],
    fallback: [Card],
    using generator: inout some RandomNumberGenerator
  ) -> Card? {
    if bucket.isEmpty == false {
      return bucket.remove(at: Int.random(in: 0..<bucket.count, using: &generator))
    }

    guard fallback.isEmpty == false else { return nil }
    return fallback[Int.random(in: 0..<fallback.count, using: &generator)]
  }

  private static func weightedRarity(
    _ weights: [RarityWeight],
    using generator: inout some RandomNumberGenerator
  ) -> Card.Rarity {
    let total = weights.reduce(0) { $0 + $1.weight }
    guard total > 0 else { return .common }
    var roll = Double.random(in: 0..<total, using: &generator)

    for entry in weights {
      roll -= entry.weight
      if roll <= 0 { return entry.rarity }
    }

    return .common
  }
}

// MARK: - Deterministic randomness

/// SplitMix64. Lets a test pin a pack to an exact set of pulls, and lets the UI
/// re-derive the same wrapper crinkle for the same pack id on every redraw.
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
  private var state: UInt64

  public init(seed: UInt64) {
    state = seed
  }

  public init(seed: UUID) {
    let bytes = seed.uuid
    self.init(
      seed: UInt64(bytes.0) << 56 | UInt64(bytes.1) << 48 | UInt64(bytes.2) << 40
        | UInt64(bytes.3) << 32 | UInt64(bytes.4) << 24 | UInt64(bytes.5) << 16
        | UInt64(bytes.6) << 8 | UInt64(bytes.7)
    )
  }

  public mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
  }
}
