import Foundation
import Networking

public struct BuylistQuote: Equatable, Sendable {
  public let provider: PriceProvider
  public let retail: [PriceSeriesKind: Decimal]
  public let buylist: [PriceSeriesKind: Decimal]

  public init(
    provider: PriceProvider,
    retail: [PriceSeriesKind: Decimal],
    buylist: [PriceSeriesKind: Decimal]
  ) {
    self.provider = provider
    self.retail = retail
    self.buylist = buylist
  }

  public init?(provider: PriceProvider, retail: PriceHistory?, buylist: PriceHistory?) {
    let buying = buylist?.series.compactMapValues { $0.last?.amount } ?? [:]
    guard buying.isEmpty == false else { return nil }

    self.init(
      provider: provider,
      retail: retail?.series.compactMapValues { $0.last?.amount } ?? [:],
      buylist: buying
    )
  }

  public func buylist(for kind: PriceSeriesKind) -> Decimal? { buylist[kind] }

  public func spread(for kind: PriceSeriesKind) -> Double? {
    guard let sell = retail[kind], let buy = buylist[kind] else { return nil }
    let ask = (sell as NSDecimalNumber).doubleValue
    let bid = (buy as NSDecimalNumber).doubleValue
    guard ask > 0, bid > 0, ask.isFinite, bid.isFinite, ask >= bid else { return nil }
    return (ask - bid) / ask
  }

  public var finishes: [PriceSeriesKind] {
    PriceSeriesKind.allCases.filter { buylist[$0] != nil }
  }
}
