@testable import CardDetail
import Foundation
import Networking
import Testing

struct BuylistQuoteTests {
  private func decimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
  }

  private func quote(retail: [PriceSeriesKind: String], buylist: [PriceSeriesKind: String]) -> BuylistQuote {
    BuylistQuote(
      provider: .cardkingdom,
      retail: retail.mapValues(decimal),
      buylist: buylist.mapValues(decimal)
    )
  }

  @Test func theRatioShouldBeTheBuyPriceOverTheVendorsOwnRetailPrice() {
    let subject = quote(retail: [.normal: "100.00", .foil: "200.00"], buylist: [.normal: "50.00", .foil: "120.00"])

    #expect(subject.ratio(for: .normal) == 0.5)
    #expect(subject.ratio(for: .foil) == 0.6)
    #expect(subject.buylist(for: .foil) == decimal("120.00"))
  }

  @Test func withoutBothPrices_thereShouldBeNoRatio() {
    let subject = quote(retail: [.normal: "100.00"], buylist: [.normal: "50.00", .foil: "120.00"])

    #expect(subject.ratio(for: .foil) == nil)
    #expect(subject.ratio(for: .etched) == nil)
    #expect(subject.buylist(for: .foil) == decimal("120.00"))
  }

  @Test func aBuyPriceAboveRetailOrAtZeroShouldHaveNoRatio() {
    #expect(quote(retail: [.normal: "1.00"], buylist: [.normal: "2.00"]).ratio(for: .normal) == nil)
    #expect(quote(retail: [.normal: "0.00"], buylist: [.normal: "0.00"]).ratio(for: .normal) == nil)
  }
}
