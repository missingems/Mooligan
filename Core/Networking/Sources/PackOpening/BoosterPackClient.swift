import ComposableArchitecture
import Foundation
import ScryfallKit

/// Stocks the shelf and rolls packs.
public protocol BoosterPackClient: Sendable {
  /// Every set the simulator is willing to sell packs of, newest first.
  func products() async throws -> [PackProduct]

  /// Rolls one pack. `seed` pins the result, which is what lets a torn-open
  /// pack survive a state restoration without re-rolling different cards.
  func open(product: PackProduct, seed: UUID) async throws -> BoosterPack
}

public extension BoosterPackClient {
  func open(product: PackProduct) async throws -> BoosterPack {
    try await open(product: product, seed: UUID())
  }
}

public enum BoosterPackClientKey: DependencyKey {
  public static var liveValue: any BoosterPackClient { LiveBoosterPackClient() }

#if DEBUG
  public static var previewValue: any BoosterPackClient { MockBoosterPackClient() }
  public static var testValue: any BoosterPackClient { MockBoosterPackClient() }
#endif
}

public extension DependencyValues {
  var boosterPackClient: any BoosterPackClient {
    get { self[BoosterPackClientKey.self] }
    set { self[BoosterPackClientKey.self] = newValue }
  }
}

// MARK: - Live

public struct LiveBoosterPackClient: BoosterPackClient {
  @Dependency(\.gameSetRequestClient) private var setClient
  @Dependency(\.boosterPoolSource) private var poolSource
  @Dependency(\.boosterOddsSource) private var oddsSource

  private let cache = BoosterPoolCache()

  public init() {}

  public func products() async throws -> [PackProduct] {
    let (_, sets) = try await setClient.getSets(queryType: .all)

    return
      sets
      .filter(\.sellsBoosters)
      .sorted { ($0.releasedAt ?? "") > ($1.releasedAt ?? "") }
      .flatMap { set in
        set.stockedPackKinds.map { PackProduct(set: set, kind: $0) }
      }
  }

  public func open(product: PackProduct, seed: UUID) async throws -> BoosterPack {
    // Started before the pool rather than after it. The two have nothing to say
    // to each other, and running them back to back made the wait the sum of a
    // database read and a network fetch instead of the longer of the two.
    async let pendingOdds = oddsSource.odds(forSet: product.set.code, kind: product.kind)

    let pool: BoosterCardPool

    // Keyed by the product, not the set: a Collector Booster of a set draws
    // from a wider pool than a Play Booster of the same set, so the two cannot
    // share an entry.
    if let cached = await cache.pool(for: product) {
      pool = cached
    } else {
      pool = try await poolSource.pool(
        forSet: product.set.code,
        companions: await companionSetCodes(for: product)
      )
      await cache.store(pool, for: product)
    }

    // Odds never fail the open: a set MTGJSON doesn't cover, a network drop, or
    // simply taking too long, all mean `BoosterPackOdds.fallback` — the cards
    // are the only thing that has to be real for a pack to be worth opening.
    let odds = await pendingOdds

    var generator = SeededRandomNumberGenerator(seed: seed)
    let cards = BoosterPackRoller.roll(kind: product.kind, from: pool, odds: odds, using: &generator)

    guard cards.isEmpty == false else {
      throw BoosterPoolSourceError.emptyPool(setCode: product.set.code)
    }

    return BoosterPack(id: seed, product: product, cards: cards)
  }

  /// The companion products a Collector Booster of this set also contains.
  ///
  /// Read from the set list rather than hard-coded: Scryfall already models the
  /// relationship, as a child set of type `eternal` or `commander`. The list is
  /// served from the local store, so this is a database read and not another
  /// trip to Scryfall.
  ///
  /// Returns nothing rather than failing when the list is unavailable: a
  /// collector pack of the main set alone is what this shipped as until now,
  /// and is a better outcome than a pack that will not open.
  private func companionSetCodes(for product: PackProduct) async -> [String] {
    guard product.kind == .collector else { return [] }
    guard let sets = try? await setClient.getSets(queryType: .all).1 else { return [] }
    return product.set.companionSetCodes(in: sets)
  }
}

/// Keeps a set's sampled pool for the life of the process.
///
/// Opening five packs in a row from the same shelf slot is the common case, and
/// this turns everything after the first into a pure in-memory roll.
actor BoosterPoolCache {
  private var pools: [String: BoosterCardPool] = [:]

  func pool(for product: PackProduct) -> BoosterCardPool? {
    pools[Self.key(for: product)]
  }

  func store(_ pool: BoosterCardPool, for product: PackProduct) {
    pools[Self.key(for: product)] = pool
  }

  private static func key(for product: PackProduct) -> String {
    "\(product.set.code.lowercased())/\(product.kind.rawValue)"
  }
}

// MARK: - Which sets get shelf space

public extension MTGSet {
  /// Sets that were actually sold in randomised boosters. Keeps the shelf free
  /// of token sets, memorabilia, promo dumps, digital-only releases, and two
  /// things that look like they belong but aren't: Commander products (sold as
  /// fixed preconstructed decks — there was never a random pack to open), and
  /// a set that hasn't released yet, which cannot be bought as anything.
  var sellsBoosters: Bool {
    @Dependency(\.date.now) var now: Date
    guard digital == false, cardCount >= 60, date <= now else { return false }

    return switch setType {
    case .core, .expansion, .masters, .draftInnovation, .starter:
      true
    default:
      false
    }
  }

  /// The sets a Collector Booster of this set draws from besides this one.
  ///
  /// Checked against MTGJSON's real sheets for two sets. The Hobbit's collector
  /// `boosterfun` sheet is half The Hobbit Eternal — 66 of its 132 cards — and
  /// its box topper is that set outright; Bloomburrow's carries a 40-card sheet
  /// of Bloomburrow Commander cards and more of them among the showcase rares.
  /// Both are exactly what Scryfall files as a child set of type `eternal` or
  /// `commander`, which is what this looks for.
  ///
  /// Play Boosters are not covered by this, and should not be: every sheet of
  /// The Hobbit's play booster is The Hobbit alone. (Bloomburrow's has ten
  /// Special Guests in it, which are a set of their own with no parent, so they
  /// are out of reach here — a small, known gap in both products.)
  func companionSetCodes(in sets: [MTGSet]) -> [String] {
    sets
      .filter { $0.parentSetCode?.lowercased() == code.lowercased() }
      .filter { $0.setType == .commander || $0.setType == .eternal }
      .filter { $0.digital == false && $0.cardCount > 0 }
      .map(\.code)
  }

  /// Collector boosters only exist for sets from roughly Throne of Eldraine on,
  /// and draft boosters were retired when Play Boosters arrived in 2024.
  var stockedPackKinds: [BoosterPackKind] {
    let year = Int((releasedAt ?? "").prefix(4)) ?? 0

    var kinds: [BoosterPackKind] = []
    if year >= 2024 { kinds.append(.play) }
    if year < 2024 || kinds.isEmpty { kinds.append(.draft) }
    if year >= 2019 { kinds.append(.collector) }
    return kinds
  }
}
