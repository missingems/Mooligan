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

    return BoosterCardPool(
      commons: common.filter { $0.isBasicLand == false },
      uncommons: (try? await uncommons) ?? [],
      rares: (try? await rares) ?? [],
      mythics: (try? await mythics) ?? [],
      lands: common.filter(\.isBasicLand)
    )
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
    .filter(\.isBoosterEligible)
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
}
