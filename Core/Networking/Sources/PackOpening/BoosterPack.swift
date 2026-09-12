import Foundation
import ScryfallKit

// MARK: - Pack composition

/// Which slot of a booster a card came out of.
///
/// Kept separate from `Card.rarity` because the interesting slots — the wildcard
/// and the foil — can come back at *any* rarity, and the reveal UI wants to
/// build anticipation around the slot rather than the rarity it happened to roll.
public enum PackSlotKind: String, Equatable, Sendable, CaseIterable {
  case common
  case uncommon
  case rareOrMythic
  case land
  case wildcard
  case foilWildcard

  public var title: String {
    switch self {
    case .common: String(localized: "Common")
    case .uncommon: String(localized: "Uncommon")
    case .rareOrMythic: String(localized: "Rare or Mythic")
    case .land: String(localized: "Land")
    case .wildcard: String(localized: "Wildcard")
    case .foilWildcard: String(localized: "Foil Wildcard")
    }
  }

  /// Slots the reveal sequence saves for last, because they are the ones worth
  /// waiting for.
  public var isHeadliner: Bool {
    switch self {
    case .rareOrMythic, .foilWildcard: true
    case .common, .uncommon, .land, .wildcard: false
    }
  }
}

/// One position in a booster, before it has been filled.
public struct PackSlotTemplate: Equatable, Sendable {
  public let kind: PackSlotKind

  /// Probability that this slot comes back as a traditional foil.
  public let foilChance: Double

  public init(kind: PackSlotKind, foilChance: Double = 0) {
    self.kind = kind
    self.foilChance = foilChance
  }
}

/// The three products the vending machine stocks.
///
/// Compositions follow Wizards' published contents, simplified where a real
/// pack's rules are set-specific (The List, art cards, serialised inserts):
/// those positions collapse into the wildcard slots.
public enum BoosterPackKind: String, Equatable, Sendable, CaseIterable, Identifiable {
  case play
  case draft
  case collector

  public nonisolated var id: String { rawValue }

  public var title: String {
    switch self {
    case .play: String(localized: "Play Booster")
    case .draft: String(localized: "Draft Booster")
    case .collector: String(localized: "Collector Booster")
    }
  }

  public var shortTitle: String {
    switch self {
    case .play: String(localized: "PLAY")
    case .draft: String(localized: "DRAFT")
    case .collector: String(localized: "COLLECTOR")
    }
  }

  public var slots: [PackSlotTemplate] {
    switch self {
    case .play:
      // 7 commons, 3 uncommons, 1 rare/mythic, 1 non-foil wildcard,
      // 1 traditional foil wildcard, 1 land. 14 cards.
      Array(repeating: PackSlotTemplate(kind: .common), count: 7)
        + Array(repeating: PackSlotTemplate(kind: .uncommon), count: 3)
        + [
          PackSlotTemplate(kind: .rareOrMythic),
          PackSlotTemplate(kind: .wildcard),
          PackSlotTemplate(kind: .foilWildcard, foilChance: 1),
          PackSlotTemplate(kind: .land, foilChance: 0.2),
        ]

    case .draft:
      // The pre-2024 15-card configuration: a foil turns up in roughly a
      // third of packs, in place of a common.
      Array(repeating: PackSlotTemplate(kind: .common), count: 10)
        + Array(repeating: PackSlotTemplate(kind: .uncommon), count: 3)
        + [
          PackSlotTemplate(kind: .rareOrMythic),
          PackSlotTemplate(kind: .land, foilChance: 0.35),
        ]

    case .collector:
      // Everything shiny: 15 cards, weighted hard toward the top end.
      Array(repeating: PackSlotTemplate(kind: .common, foilChance: 1), count: 5)
        + Array(repeating: PackSlotTemplate(kind: .uncommon, foilChance: 1), count: 4)
        + Array(repeating: PackSlotTemplate(kind: .wildcard, foilChance: 1), count: 2)
        + Array(repeating: PackSlotTemplate(kind: .rareOrMythic), count: 3)
        + [PackSlotTemplate(kind: .foilWildcard, foilChance: 1)]
    }
  }

  public var cardCount: Int { slots.count }
}

// MARK: - Products

/// One SKU on the shelf: a set, in one of the three pack configurations.
public struct PackProduct: Equatable, Identifiable, Sendable {
  public let set: MTGSet
  public let kind: BoosterPackKind

  public nonisolated var id: String { "\(set.code)-\(kind.rawValue)" }
  public var setCode: String { self.set.code.uppercased() }
  public var iconURL: URL? { URL(string: self.set.iconSvgUri) }

  public init(set: MTGSet, kind: BoosterPackKind) {
    self.set = set
    self.kind = kind
  }
}

// MARK: - Results

/// A single card as it came out of a pack.
///
/// `id` is unique per pull rather than per card: a pack can legitimately contain
/// the same common twice, and `ForEach` needs to tell them apart.
public struct PulledCard: Equatable, Identifiable, Sendable {
  public let id: UUID
  public let card: Card
  public let slot: PackSlotKind
  public let isFoil: Bool

  /// Chance a slot of this kind yields this exact printing, or nil when the
  /// set's rarity counts were not available to work it out from.
  public let pullChance: Double?

  public init(
    id: UUID = UUID(),
    card: Card,
    slot: PackSlotKind,
    isFoil: Bool,
    pullChance: Double? = nil
  ) {
    self.id = id
    self.card = card
    self.slot = slot
    self.isFoil = isFoil
    self.pullChance = pullChance
  }

  /// The chance as "1 in n", which is how pull rates are always quoted.
  public var oddsDescription: String? {
    guard let pullChance, pullChance > 0 else { return nil }
    return "1 in \((1 / pullChance).rounded().formatted(.number.grouping(.automatic)))"
  }

  public var rarity: Card.Rarity { card.rarity }

  /// Market price for the pulled card, quoting the finish it was actually
  /// pulled in wherever that finish has a price of its own.
  ///
  /// Falls back to the other finish rather than reporting nothing. Refusing to
  /// cross finishes is more precise in principle — a foil and its non-foil
  /// printing are separate products at different prices — but in practice
  /// Scryfall lists only one of the two for a great many printings, and the
  /// rares and mythics people most want a number for were the ones most often
  /// coming back blank. A near-enough price beats a card that shows its rarity
  /// and nothing else, and it keeps the pack total honest: summing only the
  /// finishes that happened to have a price was under-reporting every pack.
  ///
  /// Parsed against a fixed locale: Scryfall always writes "1.50", which a
  /// comma-decimal locale would otherwise misread.
  public var price: Decimal? {
    let preferred = isFoil ? card.prices.usdFoil : card.prices.usd
    let alternate = isFoil ? card.prices.usd : card.prices.usdFoil
    let raw = preferred ?? alternate ?? card.prices.usdEtched

    return raw.flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
  }

  /// `true` when the price shown had to be borrowed from the other finish, so
  /// the UI can mark it as approximate rather than quoting it as exact.
  public var isPriceApproximate: Bool {
    guard price != nil else { return false }
    return (isFoil ? card.prices.usdFoil : card.prices.usd) == nil
  }

  /// Ranking used to pick the pack's headline card, and to decide which pulls
  /// deserve the "hit" treatment during the reveal.
  public var excitement: Int {
    var score = switch rarity {
    case .mythic: 400
    case .rare: 300
    case .special: 250
    case .bonus: 200
    case .uncommon: 100
    case .common: 0
    }

    if isFoil { score += 60 }
    if let price, price >= 5 { score += 40 }
    return score
  }

  /// Whether the reveal should stop and make a fuss about this card.
  public var isHit: Bool {
    rarity == .mythic || rarity == .rare || isFoil || (price ?? 0) >= 5
  }
}

/// A rolled pack, ready to be torn open.
public struct BoosterPack: Equatable, Identifiable, Sendable {
  public let id: UUID
  public let product: PackProduct
  public let cards: [PulledCard]

  public init(id: UUID = UUID(), product: PackProduct, cards: [PulledCard]) {
    self.id = id
    self.product = product
    self.cards = cards
  }

  public var totalValue: Decimal {
    cards.reduce(Decimal.zero) { $0 + ($1.price ?? 0) }
  }

  /// How many of each rarity came out, best first. Only rarities actually
  /// present appear, so a pack with no mythic simply has no mythic entry
  /// rather than a zero.
  public var rarityCounts: [(rarity: Card.Rarity, count: Int)] {
    Dictionary(grouping: cards, by: \.rarity)
      .map { (rarity: $0.key, count: $0.value.count) }
      .sorted { $0.rarity > $1.rarity }
  }

  public var bestPull: PulledCard? {
    cards.max { lhs, rhs in
      if lhs.excitement == rhs.excitement {
        return (lhs.price ?? 0) < (rhs.price ?? 0)
      }
      return lhs.excitement < rhs.excitement
    }
  }

  /// Reveal order: filler first, headliners last, so the pack builds instead of
  /// peaking on card one.
  public var revealOrder: [PulledCard] {
    cards.enumerated()
      .sorted { lhs, rhs in
        if lhs.element.excitement == rhs.element.excitement {
          return lhs.offset < rhs.offset
        }
        return lhs.element.excitement < rhs.element.excitement
      }
      .map(\.element)
  }
}


public extension Card {
  /// `true` if this printing only exists as a foil, `false` if it only exists
  /// non-foil, and `nil` when both were printed and the slot's own odds decide.
  var availableFoilness: Bool? {
    let hasFoil = finishes.contains(.foil) || finishes.contains(.etched)
    let hasNonFoil = finishes.contains(.nonfoil)

    if hasFoil, hasNonFoil == false { return true }
    if hasNonFoil, hasFoil == false { return false }
    return nil
  }
}
