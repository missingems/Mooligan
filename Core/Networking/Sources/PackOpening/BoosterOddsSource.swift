import ComposableArchitecture
import Foundation
import ScryfallKit

/// One rarity's share of a slot, as a fraction of that slot's total weight.
public struct RarityWeight: Equatable, Sendable, Codable {
  public let rarity: Card.Rarity
  public let weight: Double

  public init(rarity: Card.Rarity, weight: Double) {
    self.rarity = rarity
    self.weight = weight
  }
}

/// The odds `BoosterPackRoller` draws against for one set's one product.
///
/// Every number here started as a hand-typed guess. Where MTGJSON has the set,
/// these are now real weights recovered from Wizards' own booster
/// configuration — the file format WotC ships to printers — rather than
/// figures estimated from memory. `fallback` is what a set MTGJSON doesn't
/// cover, or a booster shape the parser doesn't recognise, gets instead: still
/// a guess, just the least-wrong one available, and never presented as more.
public struct BoosterPackOdds: Equatable, Sendable, Codable {
  /// Chance the guaranteed rare/mythic slot upgrades to mythic.
  public let mythicChance: Double
  /// Rarity distribution of the plain any-rarity ("wildcard") slot.
  public let wildcardWeights: [RarityWeight]
  /// Rarity distribution of the guaranteed-foil any-rarity slot.
  ///
  /// Real booster data shows this is a materially different distribution from
  /// the plain wildcard slot — not the same weights with a foil coin-flip on
  /// top. In a Play Booster the plain wildcard leans uncommon/rare; the foil
  /// slot leans back toward common, closer to the pack's ordinary rarity mix.
  /// Treating them as one shared table (the original version of this code did)
  /// silently wrongs whichever slot borrows the other's numbers.
  public let foilWildcardWeights: [RarityWeight]

  public init(
    mythicChance: Double,
    wildcardWeights: [RarityWeight],
    foilWildcardWeights: [RarityWeight]
  ) {
    self.mythicChance = mythicChance
    self.wildcardWeights = wildcardWeights
    self.foilWildcardWeights = foilWildcardWeights
  }

  /// Used whenever MTGJSON has nothing usable for a set: no booster entry, or
  /// none of its sheets look like a slot this roller knows how to fill.
  ///
  /// The mythic rate is the one number here Wizards has stated directly — 1-in-8
  /// through 2020, 1-in-7 from Zendikar Rising on, and every set this shelf can
  /// offer post-dates that change. The two wildcard tables are estimates in the
  /// same spirit as before: nobody has published exact wildcard percentages, so
  /// this is a plausible shape rather than a sourced one.
  public static let fallback = BoosterPackOdds(
    mythicChance: 1.0 / 7.0,
    wildcardWeights: [
      RarityWeight(rarity: .common, weight: 0.58),
      RarityWeight(rarity: .uncommon, weight: 0.30),
      RarityWeight(rarity: .rare, weight: 0.10),
      RarityWeight(rarity: .mythic, weight: 0.02),
    ],
    foilWildcardWeights: [
      RarityWeight(rarity: .common, weight: 0.58),
      RarityWeight(rarity: .uncommon, weight: 0.30),
      RarityWeight(rarity: .rare, weight: 0.10),
      RarityWeight(rarity: .mythic, weight: 0.02),
    ]
  )
}

/// Supplies `BoosterPackOdds` for a set's product.
///
/// Never throws: a set with no MTGJSON coverage and a dropped network request
/// both just mean `BoosterPackOdds.fallback`. Opening a pack should never fail
/// because the *odds* couldn't be fetched — only because the *cards* couldn't.
public protocol BoosterOddsSource: Sendable {
  func odds(forSet setCode: String, kind: BoosterPackKind) async -> BoosterPackOdds
}

public enum BoosterOddsSourceKey: DependencyKey {
  public static var liveValue: any BoosterOddsSource {
    CachedBoosterOddsSource(upstream: MTGJSONBoosterOddsSource())
  }

#if DEBUG
  public static var previewValue: any BoosterOddsSource { MockBoosterOddsSource() }
  public static var testValue: any BoosterOddsSource { MockBoosterOddsSource() }
#endif
}

public extension DependencyValues {
  var boosterOddsSource: any BoosterOddsSource {
    get { self[BoosterOddsSourceKey.self] }
    set { self[BoosterOddsSourceKey.self] = newValue }
  }
}

#if DEBUG
/// Always the fallback odds. Deterministic, and needs no network — used by
/// previews, the PackOpening runner, and `-uiTestMode`.
public struct MockBoosterOddsSource: BoosterOddsSource {
  public init() {}

  public func odds(forSet setCode: String, kind: BoosterPackKind) async -> BoosterPackOdds {
    .fallback
  }
}
#endif
