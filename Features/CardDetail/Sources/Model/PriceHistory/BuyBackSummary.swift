import Foundation
import Networking

/// The buy back ratio across a card's finishes, lowest to highest, with the figures behind it.
struct BuyBackSummary: Equatable, Sendable {
  let provider: PriceProvider
  let ratioText: String
  let finishes: [FinishBuyBack]
  /// Where to sell the card to the vendor, when it publishes its buylist on the web.
  let sellURL: URL?

  var isAvailable: Bool { finishes.isEmpty == false }
}
