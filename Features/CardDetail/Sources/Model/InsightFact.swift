import Foundation

/// One row of the facts under an explanation: a name on the left and one value on the right.
struct InsightFact: Equatable, Hashable, Sendable {
  let title: String
  var value: String?
  /// Mana symbols drawn in place of a value, as the card prints them: "{2}", "{R}".
  var symbols: [String] = []
}
