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

    if let cached = await cache.pool(forSet: product.set.code) {
      pool = cached
    } else {
      pool = try await poolSource.pool(forSet: product.set.code)
      await cache.store(pool, forSet: product.set.code)
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
}

/// Keeps a set's sampled pool for the life of the process.
///
/// Opening five packs in a row from the same shelf slot is the common case, and
/// this turns everything after the first into a pure in-memory roll.
actor BoosterPoolCache {
  private var pools: [String: BoosterCardPool] = [:]

  func pool(forSet setCode: String) -> BoosterCardPool? {
    pools[setCode.lowercased()]
  }

  func store(_ pool: BoosterCardPool, forSet setCode: String) {
    pools[setCode.lowercased()] = pool
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
