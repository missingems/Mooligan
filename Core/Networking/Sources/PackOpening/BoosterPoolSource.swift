import ComposableArchitecture
import Foundation
import ScryfallKit

/// Supplies the cards a set's boosters draw from.
public protocol BoosterPoolSource: Sendable {
  func pool(forSet setCode: String) async throws -> BoosterCardPool
}

public enum BoosterPoolSourceError: Error, Equatable {
  /// No source could produce enough cards for the set — usually a set the bulk
  /// sync hasn't reached and that Scryfall has no boosterable printings for.
  case emptyPool(setCode: String)
}

// MARK: - Local database

/// Reads the bulk-synced `cards` table. This is the fast path: a pack rolls
/// entirely offline, in a single database read, with no Scryfall round trip.
public struct DatabaseBoosterPoolSource: BoosterPoolSource {
  /// How many printings to sample per rarity. Comfortably more than any pack
  /// needs, so draws stay varied without decoding an entire set.
  private let samplePerRarity: Int

  private let store = CardStore()

  public init(samplePerRarity: Int = 80) {
    self.samplePerRarity = samplePerRarity
  }

  public func pool(forSet setCode: String) async throws -> BoosterCardPool {
    try await store.boosterPool(inSet: setCode, samplePerRarity: samplePerRarity)
  }
}

// MARK: - Scryfall

/// Four rarity-scoped searches against Scryfall. Only used when the local
/// database has nothing for the set — i.e. before the first bulk sync finishes.
public struct ScryfallBoosterPoolSource: BoosterPoolSource {
  private let client: ScryfallClient

  public init(client: ScryfallClient = ScryfallClient()) {
    self.client = client
  }

  public func pool(forSet setCode: String) async throws -> BoosterCardPool {
    async let commons = cards(setCode: setCode, rarity: "common")
    async let uncommons = cards(setCode: setCode, rarity: "uncommon")
    async let rares = cards(setCode: setCode, rarity: "rare")
    async let mythics = cards(setCode: setCode, rarity: "mythic")

    let common = try await commons
    let uncommon = (try? await uncommons) ?? []
    let rare = (try? await rares) ?? []
    let mythic = (try? await mythics) ?? []

    func pool(eligible: (Card) -> Bool) -> BoosterCardPool {
      BoosterCardPool(
        commons: common.filter { eligible($0) && $0.isBasicLand == false },
        uncommons: uncommon.filter(eligible),
        rares: rare.filter(eligible),
        mythics: mythic.filter(eligible),
        lands: common.filter(\.isBasicLand)
      )
    }

    let strict = pool(eligible: \.isBoosterEligible)
    if strict.isUsable { return strict }

    // `booster` reads false across the entire set for a handful of real
    // products (Star Trek, Marvel Super Heroes, The Hobbit, Secrets of
    // Strixhaven, at least) — Scryfall's booster-contents confirmation hasn't
    // caught up with them, not a sign the set was never sold in packs. The
    // shelf still offers these as products, so an empty pool here would be a
    // dead end for something the app itself just sold. Retry with the flag
    // dropped rather than leave it unopenable.
    return pool(eligible: \.isBoosterEligibleIgnoringBoosterFlag)
  }

  private func cards(setCode: String, rarity: String) async throws -> [Card] {
    try await client.searchCards(
      filters: [.set(setCode), .rarity(rarity), .in("paper")],
      unique: .cards,
      order: .set,
      includeExtras: false,
      includeMultilingual: false,
      includeVariations: false,
      page: 1
    )
    .data
    .filter { $0.oversized == false }
  }
}

// MARK: - Chaining

/// Tries each source in order and returns the first usable pool.
public struct ChainedBoosterPoolSource: BoosterPoolSource {
  private let sources: [any BoosterPoolSource]

  public init(_ sources: [any BoosterPoolSource]) {
    self.sources = sources
  }

  public func pool(forSet setCode: String) async throws -> BoosterCardPool {
    for source in sources {
      if let pool = try? await source.pool(forSet: setCode), pool.isUsable {
        return pool
      }
    }

    throw BoosterPoolSourceError.emptyPool(setCode: setCode)
  }
}

public enum BoosterPoolSourceKey: DependencyKey {
  public static var liveValue: any BoosterPoolSource {
    ChainedBoosterPoolSource([DatabaseBoosterPoolSource(), ScryfallBoosterPoolSource()])
  }

#if DEBUG
  public static var previewValue: any BoosterPoolSource { MockBoosterPoolSource() }
  public static var testValue: any BoosterPoolSource { MockBoosterPoolSource() }
#endif
}

public extension DependencyValues {
  var boosterPoolSource: any BoosterPoolSource {
    get { self[BoosterPoolSourceKey.self] }
    set { self[BoosterPoolSourceKey.self] = newValue }
  }
}

// MARK: - Card helpers

public extension Card {
  /// Basic lands fill the land slot and must stay out of the common slot,
  /// where they would otherwise crowd out real commons.
  var isBasicLand: Bool {
    (typeLine ?? "").hasPrefix("Basic")
  }

  /// Printings that actually appear in boosters. Filters out the promos,
  /// showcase-only prints and oversized cards Scryfall returns alongside them.
  var isBoosterEligible: Bool {
    booster && oversized == false && games.contains(.paper)
  }

  /// The looser bar a pool source falls back to when `isBoosterEligible`
  /// leaves nothing.
  ///
  /// Scryfall's `booster` flag reads false for every card in some real sets —
  /// Star Trek, Marvel Super Heroes, The Hobbit and Secrets of Strixhaven all
  /// do this, at minimum — which is a gap in Scryfall's own booster-contents
  /// confirmation, not evidence the set was never sold in packs. This keeps
  /// the paper/oversized checks, which are reliable, and drops only the one
  /// flag that turned out not to be.
  var isBoosterEligibleIgnoringBoosterFlag: Bool {
    oversized == false && games.contains(.paper)
  }
}
