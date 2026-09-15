import Foundation
import Networking

/// One finish's latest market price, as the toolbar shows it.
struct FinishPrice: Equatable, Sendable, Identifiable {
  let kind: PriceSeriesKind
  let label: String
  let priceText: String
  /// Without a price the item shows a dash, greyed out, and cannot be tapped.
  let isAvailable: Bool

  var id: PriceSeriesKind { kind }
}
