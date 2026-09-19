import Foundation

/// How far the on-device model has got writing about the tile for this card.
enum InsightElaboration: Equatable, Sendable {
  case pending
  /// The text so far, empty until the first words arrive.
  case writing(String)
  case written(String)
  /// Apple Intelligence is not on this device or not switched on, or it would not write about this
  /// card. The section is left out rather than left empty.
  case unavailable

  var isWriting: Bool {
    if case .writing = self { true } else { false }
  }
}
