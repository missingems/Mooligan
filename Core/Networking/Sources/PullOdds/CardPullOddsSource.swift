import Foundation
import ScryfallKit

/// Supplies how rarely a printing comes out of the sealed products it is printed in.
///
/// Never throws: a set MTGJSON has no booster data for, a printing no product
/// holds, and a download that failed all mean there are no odds to show.
public protocol CardPullOddsSource: Sendable {
  /// The card's odds in its own set's products and, where Scryfall files the set
  /// under a parent (a commander deck under its expansion), in the parent's.
  func odds(for card: Card, parentSetCode: String?) async -> CardPullOdds?
}
