import Foundation
import Networking

/// What the buylist vendor pays for one finish, and that price as a share of its own retail price.
struct FinishBuyBack: Equatable, Sendable, Identifiable {
  let kind: PriceSeriesKind
  let label: String
  let priceText: String
  let ratioText: String?

  var id: PriceSeriesKind { kind }
}
