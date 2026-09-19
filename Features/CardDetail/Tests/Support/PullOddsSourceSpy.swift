import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit

/// A pull odds source that answers every card with the odds a test gives it, and records the parent
/// set each card was asked with.
struct PullOddsSourceSpy: CardPullOddsSource {
  let odds: CardPullOdds?
  /// The parent set code of every request, in order.
  let parentSetCodes = LockIsolated<[String?]>([])

  func odds(for card: Card, parentSetCode: String?) async -> CardPullOdds? {
    parentSetCodes.withValue { $0.append(parentSetCode) }
    return odds
  }
}
