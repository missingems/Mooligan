import Foundation

/// Facts that belong together, set out like a grouped list: an optional heading above, the rows on
/// one panel, and an optional note under it.
struct InsightFactGroup: Equatable, Hashable, Sendable {
  var header: String?
  let facts: [InsightFact]
  var footer: String?
}
