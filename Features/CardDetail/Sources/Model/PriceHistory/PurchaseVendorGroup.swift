import Foundation
import Networking
import ScryfallKit

struct PurchaseVendorGroup: Equatable, Identifiable, Sendable {
  struct Offer: Equatable, Identifiable, Sendable {
    let provider: PriceProvider
    let finish: PriceSeriesKind?
    let price: Decimal?
    let currency: String
    let url: URL
    let priceText: String?
    let finishLabel: String?

    init(provider: PriceProvider, finish: PriceSeriesKind?, price: Decimal?, currency: String, url: URL) {
      self.provider = provider
      self.finish = finish
      self.price = price
      self.currency = currency
      self.url = url
      self.priceText = price?.formatted(PriceChartStyle.price(currency))
      self.finishLabel = finish.map(PriceChartStyle.label(for:))
    }

    var id: String { "\(provider.rawValue).\(finish?.rawValue ?? "all")" }
  }

  let provider: PriceProvider
  let offers: [Offer]

  var id: String { provider.rawValue }

  static func make(
    links: [PurchaseLink],
    quotes: [PriceProvider: RetailQuote],
    scryfallPrices: Card.Prices
  ) -> [PurchaseVendorGroup] {
    var order: [PriceProvider] = []
    var linksByProvider: [PriceProvider: [PurchaseLink]] = [:]
    for link in links {
      if linksByProvider[link.provider] == nil { order.append(link.provider) }
      linksByProvider[link.provider, default: []].append(link)
    }

    return order.compactMap { provider in
      let vendorLinks = linksByProvider[provider] ?? []
      let quote = quotes[provider] ?? RetailQuote.scryfall(provider, prices: scryfallPrices)
      let currency = quote?.currency ?? provider.currencyCode
      let explicit = Set(vendorLinks.compactMap(\.finish))

      var offers: [Offer] = []
      for link in vendorLinks {
        if let finish = link.finish {
          offers.append(Offer(provider: provider, finish: finish, price: quote?.prices[finish], currency: currency, url: link.url))
          continue
        }

        let quoted = PriceChartStyle.displayOrder.filter { kind in
          explicit.contains(kind) == false && quote?.prices[kind] != nil
        }
        if quoted.isEmpty {
          offers.append(Offer(provider: provider, finish: nil, price: nil, currency: currency, url: link.url))
        } else {
          offers += quoted.map { kind in
            Offer(provider: provider, finish: kind, price: quote?.prices[kind], currency: currency, url: link.url)
          }
        }
      }

      let unique = offers.reduce(into: [Offer]()) { result, offer in
        if result.contains(where: { $0.id == offer.id }) == false { result.append(offer) }
      }
      let sorted = unique.sorted { lhs, rhs in
        (lhs.finish.map(PriceChartStyle.displayRank) ?? Int.max) < (rhs.finish.map(PriceChartStyle.displayRank) ?? Int.max)
      }
      return sorted.isEmpty ? nil : PurchaseVendorGroup(provider: provider, offers: sorted)
    }
  }
}
