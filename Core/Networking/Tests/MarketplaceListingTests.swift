@testable import Networking
import Foundation
import ScryfallKit
import Testing

/// Covers which storefronts earn a row under the price chart, and the currency
/// each one is read in.
struct MarketplaceListingTests {
  private let uris = [
    "tcgplayer": "https://tcgplayer.example/card",
    "cardmarket": "https://cardmarket.example/card",
    "cardhoarder": "https://cardhoarder.example/card",
  ]

  private func decimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
  }

  @Test func whenEveryStorefrontQuotes_shouldBuildARowEach() {
    let listings = MarketplaceListing.listings(
      purchaseURIs: uris,
      prices: Card.Prices(tix: "0.05", usd: "1.50", usdFoil: "4.00", eur: "1.20", eurFoil: "3.60")
    )

    #expect(listings.map(\.marketplace) == [.tcgplayer, .cardmarket, .cardhoarder])
    #expect(listings[0].prices[.normal] == decimal("1.50"))
    #expect(listings[0].prices[.foil] == decimal("4.00"))
    #expect(listings[1].prices[.normal] == decimal("1.20"))
    #expect(listings[2].prices[.normal] == decimal("0.05"))
  }

  /// Scryfall quotes one currency per storefront, and the UI formats on that.
  @Test func whenReadingCurrencies_shouldMatchTheStorefront() {
    #expect(Marketplace.tcgplayer.currencyCode == "USD")
    #expect(Marketplace.cardmarket.currencyCode == "EUR")
    #expect(Marketplace.cardhoarder.currencyCode == "TIX")
  }

  /// MTGO tickets are not a currency; the row has to know not to print them as
  /// dollars.
  @Test func whenStorefrontIsDigital_shouldReportTickets() {
    let listings = MarketplaceListing.listings(
      purchaseURIs: uris,
      prices: Card.Prices(tix: "0.05")
    )

    #expect(listings.count == 1)
    #expect(listings.first?.isTickets == true)
    #expect(listings.first?.marketplace.isDigital == true)
  }

  @Test func whenAStorefrontHasNoLink_shouldBeDropped() {
    let listings = MarketplaceListing.listings(
      purchaseURIs: ["tcgplayer": uris["tcgplayer"]!],
      prices: Card.Prices(tix: "0.05", usd: "1.50", eur: "1.20")
    )

    #expect(listings.map(\.marketplace) == [.tcgplayer])
  }

  /// A linked storefront with no quote is a dead end, and Scryfall reports
  /// "0.00" for cards nobody stocks rather than omitting the field.
  @Test func whenAStorefrontQuotesNothing_shouldBeDropped() {
    let listings = MarketplaceListing.listings(
      purchaseURIs: uris,
      prices: Card.Prices(tix: nil, usd: "0.00", usdFoil: nil, eur: nil)
    )

    #expect(listings.isEmpty)
  }

  @Test func whenOrderingPrices_shouldReadRegularThenFoilThenEtched() {
    let listing = MarketplaceListing.listings(
      purchaseURIs: uris,
      prices: Card.Prices(usd: "1.00", usdFoil: "2.00", usdEtched: "3.00")
    ).first

    #expect(listing?.orderedPrices.map(\.kind) == [.normal, .foil, .etched])
  }

  /// The chart plots TCGplayer, so its row has to be the one the headline price
  /// agrees with — the id is what keeps the two in step.
  @Test func whenIdentifyingARow_shouldUseTheStorefront() {
    let listing = MarketplaceListing(
      marketplace: .cardmarket,
      url: URL(string: uris["cardmarket"]!)!,
      prices: [.normal: decimal("1.00")]
    )

    #expect(listing.id == "cardmarket")
  }
}
