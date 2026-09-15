import Foundation
import Networking
import ScryfallKit

enum PurchaseDropdownState: Equatable, Sendable {
  case loading
  case failed
  case loaded([PurchaseVendorGroup])

  static func make(
    links: PurchaseLinksState,
    quotes: [PriceProvider: RetailQuote],
    scryfallPrices: Card.Prices
  ) -> PurchaseDropdownState {
    switch links {
    case .idle, .loading:
      .loading
    case .failed:
      .failed
    case let .loaded(links):
      .loaded(PurchaseVendorGroup.make(links: links, quotes: quotes, scryfallPrices: scryfallPrices))
    }
  }
}
