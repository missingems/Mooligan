import Foundation
import Networking

/// Where a card's pull odds are: still to come, landed, or not to be had.
enum PullOddsStatus: Equatable, Sendable {
  case loading
  case loaded(CardPullOdds)
  /// MTGJSON has no odds for the printing, its set is not out yet, or they could not be fetched.
  /// The tile is left out.
  case unavailable

  var odds: CardPullOdds? {
    if case let .loaded(odds) = self { odds } else { nil }
  }
}
