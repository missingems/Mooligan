import Foundation

struct PriceHistoryLabels: Equatable, Sendable {
  let title: String
  let buyBack: String
  let unavailable: String
  let failed: String
  let retry: String

  init(
    title: String = String(localized: "Market Price"),
    buyBack: String = String(localized: "Buy Back"),
    unavailable: String = String(localized: "No data available"),
    failed: String = String(localized: "Couldn't load prices"),
    retry: String = String(localized: "Retry")
  ) {
    self.title = title
    self.buyBack = buyBack
    self.unavailable = unavailable
    self.failed = failed
    self.retry = retry
  }
}
