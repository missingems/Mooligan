import ComposableArchitecture
import Foundation

extension CardPagerFeature.State {
  /// The page a scrub let go over lands on, or `nil` when there is nowhere to go: nothing under the
  /// glass, or the card the pager is already on, where letting go only ends the hover.
  func landingTarget(_ id: UUID?) -> CardDetailFeature.State? {
    guard let id, id != selectedId else { return nil }
    return cards[id: id]
  }
}
