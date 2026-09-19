#if DEBUG
import Foundation
import ScryfallKit

/// The same odds for every card, with no network. Used by previews, the card
/// detail runner and `-uiTestMode`; tests pass the odds they want, or none.
public struct MockCardPullOddsSource: CardPullOddsSource {
  private let odds: CardPullOdds?

  public init(odds: CardPullOdds? = CardPullOdds(products: [
    ProductPullOdds(
      id: "fdn/play",
      name: "Play Booster",
      setName: "Foundations",
      chance: 1.0 / 168,
      foilChance: 1.0 / 2_100,
      nonFoilChance: 1.0 / 182
    ),
    ProductPullOdds(
      id: "fdn/collector",
      name: "Collector Booster",
      setName: "Foundations",
      chance: 1.0 / 140,
      foilChance: 1.0 / 140,
      nonFoilChance: 0
    ),
  ], setProducts: ["fdn/play": "Play Booster", "fdn/collector": "Collector Booster"])) {
    self.odds = odds
  }

  public func odds(for card: Card, parentSetCode: String?) async -> CardPullOdds? {
    odds
  }
}
#endif
