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

    func pool(eligible: (Card) -> Bool) -> BoosterCardPool {
      BoosterCardPool(
        commons: cards(BoosterRarityRank.common, eligible: eligible),
        uncommons: cards(BoosterRarityRank.uncommon, eligible: eligible),
        rares: cards(BoosterRarityRank.rare, eligible: eligible),
        mythics: cards(BoosterRarityRank.mythic, eligible: eligible),
        lands: landRecords.map(\.card).filter(\.isBasicLand)
      )
    }

    let strict = pool(eligible: \.isBoosterEligible)
    if strict.isUsable { return strict }

    // See `Card.isBoosterEligibleIgnoringBoosterFlag`: a handful of real sets
    // report `booster: false` on every card, which starves this bucket even
    // though the data was already fetched. Reuse it rather than re-read.
    return pool(eligible: \.isBoosterEligibleIgnoringBoosterFlag)
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
