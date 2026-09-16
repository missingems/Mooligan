import Foundation

struct PriceHistoryLabels: Equatable, Sendable {
  let title: String
  let buyBack: String
  let source: String
  let buyBackExplanation: String
  let unavailable: String
  let failed: String
  let retry: String

  init(
    title: String = String(localized: "Market Price"),
    buyBack: String = String(localized: "Buy Back"),
    source: String = String(localized: "Source"),
    buyBackExplanation: String = String(localized: "What the vendor pays for a copy, and that as a share of its own retail price."),
    unavailable: String = String(localized: "No data available"),
    failed: String = String(localized: "Couldn't load prices"),
    retry: String = String(localized: "Retry")
  ) {
    self.title = title
    self.buyBack = buyBack
    self.source = source
    self.buyBackExplanation = buyBackExplanation
    self.unavailable = unavailable
    self.failed = failed
    self.retry = retry
  }

  /// The link to a vendor's buylist, named after the vendor.
  func sell(to vendor: String) -> String {
    String(localized: "Sell to \(vendor)")
  }
}
