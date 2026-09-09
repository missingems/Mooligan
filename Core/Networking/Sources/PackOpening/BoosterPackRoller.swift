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

  /// How many distinct printings the *set* has at each rarity.
  ///
  /// Not the same as the arrays above, which are a bounded sample — a pack is
  /// rolled from eighty cards a rarity, not from the whole set. Quoting a
  /// card's odds against the sample would report the chance of pulling it out
  /// of the eighty rather than out of the set, which is a different and much
  /// rosier number. Nil where the source cannot say.
  public var rarityCounts: BoosterRarityCounts?

  public init(
    commons: [Card] = [],
    uncommons: [Card] = [],
    rares: [Card] = [],
    mythics: [Card] = [],
    lands: [Card] = [],
    rarityCounts: BoosterRarityCounts? = nil
  ) {
    self.commons = commons
    self.uncommons = uncommons
    self.rares = rares
    self.mythics = mythics
    self.lands = lands
    self.rarityCounts = rarityCounts
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

/// Distinct printings per rarity in a set.
public struct BoosterRarityCounts: Equatable, Sendable {
  public var common: Int
  public var uncommon: Int
  public var rare: Int
  public var mythic: Int
  public var land: Int

  public init(common: Int, uncommon: Int, rare: Int, mythic: Int, land: Int) {
    self.common = common
    self.uncommon = uncommon
    self.rare = rare
    self.mythic = mythic
    self.land = land
  }

  public func count(for rarity: Card.Rarity) -> Int {
    switch rarity {
    case .common: common
    case .uncommon: uncommon
    case .rare: rare
    case .mythic: mythic
    case .special, .bonus: max(rare, 1)
    }
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
      let rolledFoil = Double.random(in: 0..<1, using: &generator) < slot.foilChance

      guard
        let card = draw(slot: slot.kind, from: &remaining, fallback: pool, odds: odds, using: &generator)
      else {
        return nil
      }

      // A printing that only exists in one finish is not a coin to flip. Plenty
      // of cards are foil-only — most of a Collector Booster's showcase
      // treatments, every serialised insert — and rolling "non-foil" for one of
      // those produced a card that has never existed, priced against a finish
      // Scryfall has no number for.
      return PulledCard(
        card: card,
        slot: slot.kind,
        isFoil: card.availableFoilness ?? rolledFoil,
        pullChance: pullChance(
          of: card,
          slot: slot.kind,
          odds: odds,
          counts: pool.rarityCounts
        )
      )
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


// MARK: - Odds for one card

extension BoosterPackRoller {
  /// The chance that a given slot of this kind yields this exact printing.
  ///
  /// Two independent things multiplied: how often the slot comes back at the
  /// card's rarity at all, and how many printings of that rarity it then has to
  /// choose between. A mythic in a set with 20 mythics, out of a slot that goes
  /// mythic one time in seven, is `(1/7) / 20`.
  ///
  /// Nil when the set's rarity counts are unknown, because a chance quoted
  /// against a sample would be wrong in the flattering direction, and a wrong
  /// number here is worse than none.
  static func pullChance(
    of card: Card,
    slot: PackSlotKind,
    odds: BoosterPackOdds,
    counts: BoosterRarityCounts?
  ) -> Double? {
    guard let counts else { return nil }

    let slotChance: Double =
      switch slot {
      case .common, .uncommon:
        1
      case .land:
        1
      case .rareOrMythic:
        card.rarity == .mythic ? odds.mythicChance : 1 - odds.mythicChance
      case .wildcard:
        odds.wildcardWeights.first { $0.rarity == card.rarity }?.weight ?? 0
      case .foilWildcard:
        odds.foilWildcardWeights.first { $0.rarity == card.rarity }?.weight ?? 0
      }

    let pool = slot == .land ? counts.land : counts.count(for: card.rarity)
    guard pool > 0, slotChance > 0 else { return nil }

    return slotChance / Double(pool)
  }
}
