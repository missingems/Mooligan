@testable import CardDetail
import Foundation
import Networking
import ScryfallKit
import Testing

struct PurchaseOffersTests {
  private func link(_ provider: PriceProvider, _ finish: PriceSeriesKind?, _ path: String) -> PurchaseLink {
    PurchaseLink(provider: provider, finish: finish, url: URL(string: "https://mtgjson.com/links/\(path)")!)
  }

  @Test func shouldGroupByVendorInLinkOrderAndPriceEachFinish() {
    let groups = PurchaseVendorGroup.make(
      links: [
        link(.tcgplayer, nil, "tcg"),
        link(.cardkingdom, .foil, "ck-foil"),
        link(.cardkingdom, .normal, "ck"),
      ],
      quotes: [
        .tcgplayer: RetailQuote(currency: "USD", prices: [.normal: 20.34, .foil: 30.55]),
        .cardkingdom: RetailQuote(currency: "USD", prices: [.normal: 21.99]),
      ],
      scryfallPrices: Card.Prices()
    )

    #expect(groups.map(\.provider) == [.tcgplayer, .cardkingdom])
    #expect(groups[0].offers.map(\.id) == ["tcgplayer.normal", "tcgplayer.foil"])
    #expect(groups[0].offers.map(\.price) == [20.34, 30.55])
    #expect(Set(groups[0].offers.map(\.url)).count == 1)
    #expect(groups[1].offers.map(\.id) == ["cardkingdom.normal", "cardkingdom.foil"])
    #expect(groups[1].offers.map(\.price) == [21.99, nil])
  }

  @Test func whenTheFeedHasNoQuote_shouldPriceFromScryfallInTheVendorsCurrency() {
    let groups = PurchaseVendorGroup.make(
      links: [link(.cardmarket, nil, "mkm")],
      quotes: [:],
      scryfallPrices: Card.Prices(usd: "1.00", eur: "0.90", eurFoil: "2.50")
    )

    #expect(groups.first?.offers.map(\.id) == ["cardmarket.normal", "cardmarket.foil"])
    #expect(groups.first?.offers.map(\.price) == [0.90, 2.50])
    #expect(groups.first?.offers.allSatisfy { $0.currency == "EUR" } == true)
  }

  @Test func whenNothingIsQuoted_shouldOfferOneRowForAllFinishes() {
    let groups = PurchaseVendorGroup.make(
      links: [link(.tcgplayer, nil, "tcg")],
      quotes: [:],
      scryfallPrices: Card.Prices()
    )

    #expect(groups.first?.offers.map(\.id) == ["tcgplayer.all"])
    #expect(groups.first?.offers.first?.price == nil)
  }

  @Test func retailQuotesShouldTakeEachVendorsLatestNonZeroPrice() {
    let day: TimeInterval = 86_400
    let start = Date(timeIntervalSince1970: 1_788_000_000)
    let history = PriceHistory(
      cardID: "id",
      provider: .cardmarket,
      listType: .retail,
      currency: "EUR",
      series: [
        .normal: [
          PricePoint(date: start, amount: 1.10),
          PricePoint(date: start.addingTimeInterval(day), amount: 0),
        ],
      ]
    )
    let buylist = PriceHistory(
      cardID: "id",
      provider: .cardkingdom,
      listType: .buylist,
      series: [.normal: [PricePoint(date: start, amount: 0.50)]]
    )

    let quotes = PriceHistorySection.retailQuotes(from: [
      PriceSeriesRequest(provider: .cardmarket, listType: .retail): history,
      PriceSeriesRequest(provider: .cardkingdom, listType: .buylist): buylist,
    ])

    #expect(quotes == [.cardmarket: RetailQuote(currency: "EUR", prices: [.normal: 1.10])])
  }
}
