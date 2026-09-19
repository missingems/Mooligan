import Foundation
import ScryfallKit

extension Dictionary where Key == String, Value == MTGJSONBoosterSheet {
  /// Builds `BoosterPackOdds` from whichever sheets are unambiguously
  /// recognisable, falling back per-field otherwise.
  func odds(
    rarityByUUID: [String: Card.Rarity],
    scryfallByUUID: [String: String]
  ) -> BoosterPackOdds {
    let fallback = BoosterPackOdds.fallback

    return BoosterPackOdds(
      mythicChance: mythicChance(rarityByUUID: rarityByUUID) ?? fallback.mythicChance,
      wildcardWeights: weights(named: "wildcard", foil: false, rarityByUUID: rarityByUUID)
        ?? fallback.wildcardWeights,
      foilWildcardWeights: weights(named: "foil", foil: true, rarityByUUID: rarityByUUID)
        ?? fallback.foilWildcardWeights,
      cardShares: cardShares(rarityByUUID: rarityByUUID, scryfallByUUID: scryfallByUUID)
    )
  }

  /// Each printing's share of its own rarity, read straight off the sheets.
  ///
  /// A card's weight only means anything next to the other cards of the same
  /// rarity on the same sheet, so shares are normalised within that group. A
  /// card that appears on several sheets — a plain printing and a showcase one,
  /// say — is taken from the first by sheet name, so the answer does not depend
  /// on dictionary ordering.
  func cardShares(
    rarityByUUID: [String: Card.Rarity],
    scryfallByUUID: [String: String]
  ) -> [String: Double] {
    var shares: [String: Double] = [:]

    for name in keys.sorted() {
      guard let sheet = self[name] else { continue }

      var totalByRarity: [Card.Rarity: Double] = [:]
      for (uuid, weight) in sheet.cards {
        guard let rarity = rarityByUUID[uuid] else { continue }
        totalByRarity[rarity, default: 0] += weight
      }

      for (uuid, weight) in sheet.cards {
        guard
          let rarity = rarityByUUID[uuid],
          let scryfallID = scryfallByUUID[uuid],
          shares[scryfallID] == nil,
          let total = totalByRarity[rarity],
          total > 0
        else { continue }

        shares[scryfallID] = weight / total
      }
    }

    return shares
  }

  /// The mythic rate implied by the guaranteed rare-or-mythic slot.
  ///
  /// Matched by name (`/rare.?mythic/i`) rather than an exact string, because
  /// this one sheet's name has drifted across MTGJSON's history —
  /// "rareMythic", "rareMythicWithShowcase", "rareMythicShowcase" all appear
  /// depending on the set. Trusted only when exactly one sheet matches: a Play
  /// or Draft Booster has one such sheet, so a single match is exactly the
  /// expected, unambiguous case. A Collector Booster's several
  /// treatment-specific rare/mythic sheets ("extendedMainRareMythic",
  /// "extendedCommanderRareMythic", "rareMythicShowcase" all in the same
  /// product) each carry a *different* mythic rate for a *different* slot;
  /// there is no single "the" rate to average them into, so multiple matches
  /// here means falling back rather than quietly picking a wrong number.
  func mythicChance(rarityByUUID: [String: Card.Rarity]) -> Double? {
    let matches = self.filter { name, _ in
      name.range(of: "rare.?mythic", options: [.regularExpression, .caseInsensitive]) != nil
    }
    guard matches.count == 1, let sheet = matches.first?.value else { return nil }

    let byRarity = aggregate(sheet.cards, rarityByUUID: rarityByUUID)
    let total = byRarity.values.reduce(0, +)
    guard total > 0 else { return nil }

    return (byRarity[.mythic] ?? 0) / total
  }

  /// Rarity distribution of the sheet whose name and foil-ness exactly match.
  ///
  /// Exact name matching, not a fuzzy pattern: "wildcard" and "foil" are
  /// exactly what Play/Draft Boosters call these two slots, and matching
  /// anything looser risks pulling in a treatment-specific sheet (Collector
  /// Boosters name none of theirs either word, which is exactly why this
  /// correctly finds nothing there and falls back instead of misreading one).
  func weights(named name: String, foil: Bool, rarityByUUID: [String: Card.Rarity]) -> [RarityWeight]? {
    guard
      let sheet = self.first(where: { $0.key.caseInsensitiveCompare(name) == .orderedSame })?.value,
      sheet.foil == foil
    else {
      return nil
    }

    let byRarity = aggregate(sheet.cards, rarityByUUID: rarityByUUID)
    let total = byRarity.values.reduce(0, +)
    guard total > 0 else { return nil }

    return byRarity.map { RarityWeight(rarity: $0.key, weight: $0.value / total) }
  }

  private func aggregate(
    _ cards: [String: Double],
    rarityByUUID: [String: Card.Rarity]
  ) -> [Card.Rarity: Double] {
    var totals: [Card.Rarity: Double] = [:]
    for (uuid, weight) in cards {
      guard let rarity = rarityByUUID[uuid] else { continue }
      totals[rarity, default: 0] += weight
    }
    return totals
  }
}
