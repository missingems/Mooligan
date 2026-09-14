import Foundation

struct PriceHistoryLabels: Equatable, Sendable {
  let title: String
  let finishes: String
  let low: String
  let high: String
  let spread: String
  let buylist: String
  let unavailable: String
  let failed: String
  let retry: String
  let purchase: String
  let purchaseLinksEmpty: String
  let purchaseLinksFailed: String
  let allFinishes: String

  init(
    title: String = String(localized: "Price History"),
    finishes: String = String(localized: "Finishes"),
    low: String = String(localized: "Low"),
    high: String = String(localized: "High"),
    spread: String = String(localized: "Spread"),
    buylist: String = String(localized: "Buy List"),
    unavailable: String = String(localized: "No data available"),
    failed: String = String(localized: "Couldn't load prices"),
    retry: String = String(localized: "Retry"),
    purchase: String = String(localized: "Buy"),
    purchaseLinksEmpty: String = String(localized: "No links available"),
    purchaseLinksFailed: String = String(localized: "Couldn't load links"),
    allFinishes: String = String(localized: "All Finishes")
  ) {
    self.title = title
    self.finishes = finishes
    self.low = low
    self.high = high
    self.spread = spread
    self.buylist = buylist
    self.unavailable = unavailable
    self.failed = failed
    self.retry = retry
    self.purchase = purchase
    self.purchaseLinksEmpty = purchaseLinksEmpty
    self.purchaseLinksFailed = purchaseLinksFailed
    self.allFinishes = allFinishes
  }
}
