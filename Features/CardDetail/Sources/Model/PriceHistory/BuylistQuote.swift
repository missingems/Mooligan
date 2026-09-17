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

  /// What the vendor pays for a copy as a share of what it sells one for, both from its own lists.
  public func ratio(for kind: PriceSeriesKind) -> Double? {
    guard let sell = retail[kind], let buy = buylist[kind] else { return nil }
    let ask = sell.doubleValue
    let bid = buy.doubleValue
    guard ask > 0, bid > 0, ask.isFinite, bid.isFinite, ask >= bid else { return nil }
    return bid / ask
  }
}
