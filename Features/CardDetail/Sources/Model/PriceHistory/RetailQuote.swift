import Foundation
import Networking
import ScryfallKit

public struct RetailQuote: Equatable, Sendable {
  public let currency: String
  public let prices: [PriceSeriesKind: Decimal]

  public init(currency: String, prices: [PriceSeriesKind: Decimal]) {
    self.currency = currency
    self.prices = prices
  }

  static func scryfall(_ provider: PriceProvider, prices: Card.Prices) -> RetailQuote? {
    let raw: [PriceSeriesKind: String?] = switch provider {
    case .tcgplayer: [.normal: prices.usd, .foil: prices.usdFoil, .etched: prices.usdEtched]
    case .cardmarket: [.normal: prices.eur, .foil: prices.eurFoil, .etched: prices.eurEtched]
    default: [:]
    }
    let parsed = raw.compactMapValues { value -> Decimal? in
      guard
        let value,
        let amount = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")),
        amount > 0
      else {
        return nil
      }
      return amount
    }
    guard parsed.isEmpty == false else { return nil }
    return RetailQuote(currency: provider.currencyCode, prices: parsed)
  }
}
