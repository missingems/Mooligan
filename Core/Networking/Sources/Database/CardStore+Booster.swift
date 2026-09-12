import Foundation
import ScryfallKit
import SQLiteData

public extension CardStore {
  /// Samples the bulk-synced table for the cards a booster of `setCode` can
  /// contain.
  ///
  /// Sampling in SQL (`ORDER BY RANDOM()`) rather than loading the set and
  /// shuffling in Swift keeps this to four small reads: a large set is 300+
  /// compressed card blobs, and decoding all of them per pack would dominate
  /// the open animation.
  func boosterPool(inSet setCode: String, samplePerRarity: Int = 80) async throws -> BoosterCardPool {
    let code = setCode.lowercased()

    let (byRank, landRecords) = try await database.read {
      connection -> ([Int: [CardRecord]], [CardRecord]) in
      var byRank: [Int: [CardRecord]] = [:]

      for rank in BoosterRarityRank.sampled {
        byRank[rank] = try #sql(
          """
          SELECT \(CardRecord.columns) FROM "cards"
          WHERE "setCode" = \(bind: code)
            AND "isPaper" = 1
            AND "isDigital" = 0
            AND "rarityRank" = \(bind: rank)
          ORDER BY RANDOM() LIMIT \(bind: samplePerRarity)
          """,
          as: CardRecord.self
        )
        .fetchAll(connection)
      }

      let lands = try #sql(
        """
        SELECT \(CardRecord.columns) FROM "cards"
        WHERE "setCode" = \(bind: code)
          AND "isPaper" = 1
          AND "isDigital" = 0
          AND "typeLine" LIKE \(bind: "Basic %")
        ORDER BY RANDOM() LIMIT \(bind: 20)
        """,
        as: CardRecord.self
      )
      .fetchAll(connection)

      return (byRank, lands)
    }

    func cards(_ rank: Int, eligible: (Card) -> Bool) -> [Card] {
      (byRank[rank] ?? [])
        .map(\.card)
        .filter { eligible($0) && $0.isBasicLand == false }
    }

    func untallied(eligible: (Card) -> Bool) -> BoosterCardPool {
      BoosterCardPool(
        commons: cards(BoosterRarityRank.common, eligible: eligible),
        uncommons: cards(BoosterRarityRank.uncommon, eligible: eligible),
        rares: cards(BoosterRarityRank.rare, eligible: eligible),
        mythics: cards(BoosterRarityRank.mythic, eligible: eligible),
        lands: landRecords.map(\.card).filter(\.isBasicLand)
      )
    }

    let counts = try await rarityCounts(inSet: code)

    func pool(eligible: (Card) -> Bool) -> BoosterCardPool {
      var pool = untallied(eligible: eligible)
      pool.rarityCounts = counts
      return pool
    }

    let strict = pool(eligible: \.isBoosterEligible)
    if strict.isUsable { return strict }

    // See `Card.isBoosterEligibleIgnoringBoosterFlag`: a handful of real sets
    // report `booster: false` on every card, which starves this bucket even
    // though the data was already fetched. Reuse it rather than re-read.
    return pool(eligible: \.isBoosterEligibleIgnoringBoosterFlag)
  }

  /// How many distinct printings the set has at each rarity.
  ///
  /// Counted rather than sampled: `boosterPool` deliberately reads only a
  /// bounded slice of each rarity, and quoting a card's pull rate against that
  /// slice would report its chance of coming out of the eighty cards drawn
  /// rather than out of the set.
  func rarityCounts(inSet setCode: String) async throws -> BoosterRarityCounts {
    let code = setCode.lowercased()

    return try await database.read { connection -> BoosterRarityCounts in
      func total(rank: Int) throws -> Int {
        try #sql(
          """
          SELECT COUNT(*) FROM "cards"
          WHERE "setCode" = \(bind: code)
            AND "isPaper" = 1
            AND "isDigital" = 0
            AND "rarityRank" = \(bind: rank)
            AND "typeLine" NOT LIKE 'Basic %'
          """,
          as: Int.self
        )
        .fetchOne(connection) ?? 0
      }

      let lands = try #sql(
        """
        SELECT COUNT(*) FROM "cards"
        WHERE "setCode" = \(bind: code)
          AND "isPaper" = 1
          AND "isDigital" = 0
          AND "typeLine" LIKE 'Basic %'
        """,
        as: Int.self
      )
      .fetchOne(connection) ?? 0

      return BoosterRarityCounts(
        common: try total(rank: BoosterRarityRank.common),
        uncommon: try total(rank: BoosterRarityRank.uncommon),
        rare: try total(rank: BoosterRarityRank.rare),
        mythic: try total(rank: BoosterRarityRank.mythic),
        land: lands
      )
    }
  }
}

/// Mirrors `CardRecord.rarityRank(for:)`, which the sampling queries filter on.
enum BoosterRarityRank {
  static let common = 2
  static let uncommon = 3
  static let rare = 4
  static let mythic = 5

  static let sampled = [common, uncommon, rare, mythic]
}
