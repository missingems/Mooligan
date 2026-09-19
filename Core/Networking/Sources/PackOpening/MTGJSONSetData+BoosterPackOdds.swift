import Foundation
import ScryfallKit

extension MTGJSONSetData {
  /// Real odds for `kind`, or `BoosterPackOdds.fallback` field-by-field where
  /// this set's data doesn't yield a confident number. A set can end up with
  /// some real fields and some fallback fields — mythic rate recovered but the
  /// wildcard split not, say — rather than an all-or-nothing result, so a
  /// coverage gap in one number doesn't discard the other two.
  func odds(for kind: BoosterPackKind) -> BoosterPackOdds {
    guard
      let booster,
      let config = booster[mtgjsonKey(for: kind)] ?? fallbackConfig(for: kind, in: booster)
    else {
      return .fallback
    }

    let rarityByUUID = Dictionary(
      uniqueKeysWithValues: cards.compactMap { card in card.rarity.map { (card.uuid, $0) } }
    )
    let scryfallByUUID = Dictionary(
      cards.compactMap { card in
        card.identifiers?.scryfallId.map { (card.uuid, $0.lowercased()) }
      },
      uniquingKeysWith: { first, _ in first }
    )

    return config.sheets.odds(
      rarityByUUID: rarityByUUID,
      scryfallByUUID: scryfallByUUID
    )
  }

  /// MTGJSON's own key for this product.
  private func mtgjsonKey(for kind: BoosterPackKind) -> String {
    switch kind {
    case .play: "play"
    case .draft: "draft"
    case .collector: "collector"
    }
  }

  /// Sets that retired Draft Boosters for Play Boosters (2024 on) have no
  /// "draft" key. `stockedPackKinds` only offers `.draft` for sets old enough
  /// to have one, so this exists for the narrower case of a `.play` request
  /// against a set MTGJSON only ever gave a "draft" config: the two products
  /// are close enough in shape — commons, uncommons, one rare slot, a
  /// wildcard — that borrowing the sibling's real numbers beats a guess.
  private func fallbackConfig(
    for kind: BoosterPackKind,
    in booster: [String: MTGJSONBoosterConfig]
  ) -> MTGJSONBoosterConfig? {
    guard kind == .play else { return nil }
    return booster["draft"]
  }
}
