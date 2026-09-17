@testable import Networking
import Foundation
import ScryfallKit
import Testing

struct PurchaseLinksMapperTests {
  @Test func shouldListEveryVendorAndFinishInDisplayOrder() {
    let links = PurchaseLinksMapper.makeLinks(
      from: MTGGraphQLPurchaseUrls(
        tcgplayer: "https://mtgjson.com/links/tcg",
        cardKingdom: "https://mtgjson.com/links/ck",
        cardKingdomFoil: "https://mtgjson.com/links/ck-foil",
        cardmarket: "https://mtgjson.com/links/mkm"
      )
    )

    #expect(links.map(\.id) == ["tcgplayer.all", "cardkingdom.normal", "cardkingdom.foil", "cardmarket.all"])
    #expect(links.first?.url == URL(string: "https://mtgjson.com/links/tcg"))
  }

  @Test func whenAVendorHasNoLink_shouldLeaveItOut() {
    let links = PurchaseLinksMapper.makeLinks(
      from: MTGGraphQLPurchaseUrls(tcgplayer: "https://mtgjson.com/links/tcg", cardKingdom: "  ")
    )

    #expect(links.map(\.provider) == [.tcgplayer])
  }

  @Test func shouldOnlyAcceptSecureWebLinks() {
    let links = PurchaseLinksMapper.makeLinks(
      from: MTGGraphQLPurchaseUrls(
        tcgplayer: "http://mtgjson.com/links/tcg",
        cardKingdom: "javascript:alert(1)",
        cardKingdomFoil: "https://",
        cardmarket: "https://mtgjson.com/links/mkm"
      )
    )

    #expect(links.map(\.id) == ["cardmarket.all"])
  }

  @Test func whenTheCardHasNoPurchaseUrls_shouldBeEmpty() {
    #expect(PurchaseLinksMapper.makeLinks(from: nil).isEmpty)
  }
}

struct ScryfallPurchaseLinksTests {
  private func card(purchaseUris: [String: String]?, prices: Card.Prices) -> Card {
    var card = Card.mock()
    card.purchaseUris = purchaseUris
    card.prices = prices
    return card
  }

  private let uris = [
    "tcgplayer": "https://www.tcgplayer.com/product/1",
    "cardmarket": "https://www.cardmarket.com/product/1",
    "cardhoarder": "https://www.cardhoarder.com/cards/1",
  ]

  @Test func shouldLinkEveryQuotedFinishButNeverTickets() {
    let links = ScryfallPurchaseLinks.makeLinks(
      for: card(purchaseUris: uris, prices: Card.Prices(tix: "0.02", usd: "1.00", usdFoil: "3.00", eur: "0.90"))
    )

    #expect(links.map(\.id) == ["tcgplayer.normal", "tcgplayer.foil", "cardmarket.normal"])
    #expect(links.contains { $0.url.host?.contains("cardhoarder") == true } == false)
  }

  @Test func whenAStorefrontHasALinkButNoQuote_shouldStillOfferIt() {
    let links = ScryfallPurchaseLinks.makeLinks(for: card(purchaseUris: uris, prices: Card.Prices()))

    #expect(links.map(\.id) == ["tcgplayer.all", "cardmarket.all"])
  }

  @Test func whenScryfallHasNoLinks_shouldBeEmpty() {
    #expect(ScryfallPurchaseLinks.makeLinks(for: card(purchaseUris: nil, prices: Card.Prices(usd: "1.00"))).isEmpty)
  }
}

struct FallbackPurchaseLinksClientTests {
  private struct Failing: PurchaseLinksClient {
    func purchaseLinks(for card: Card) async throws -> [PurchaseLink] {
      throw PriceHistoryClientError.server("Operation 'CardPurchaseUrls' is not allowed.")
    }
  }

  private struct Empty: PurchaseLinksClient {
    func purchaseLinks(for card: Card) async throws -> [PurchaseLink] { [] }
  }

  private var card: Card {
    var card = Card.mock()
    card.purchaseUris = ["tcgplayer": "https://www.tcgplayer.com/product/1"]
    card.prices = Card.Prices(usd: "1.00")
    return card
  }

  @Test func whenMTGJSONFails_shouldFallBackToScryfall() async throws {
    let links = try await FallbackPurchaseLinksClient(primary: Failing()).purchaseLinks(for: card)

    #expect(links.map(\.id) == ["tcgplayer.normal"])
  }

  @Test func whenMTGJSONHasNoLinks_shouldFallBackToScryfall() async throws {
    let links = try await FallbackPurchaseLinksClient(primary: Empty()).purchaseLinks(for: card)

    #expect(links.map(\.id) == ["tcgplayer.normal"])
  }

  @Test func whenMTGJSONHasLinks_shouldUseThem() async throws {
    let links = try await FallbackPurchaseLinksClient(primary: MockPurchaseLinksClient()).purchaseLinks(for: card)

    #expect(links.map(\.id) == ["tcgplayer.all", "cardkingdom.normal", "cardkingdom.foil", "cardmarket.all"])
  }
}

@Suite struct FlakyPriceHistoryClientTests {
  @Test func shouldFailTheConfiguredNumberOfTimesPerCardThenSucceed() async throws {
    let client = FlakyPriceHistoryClient(failuresPerCard: 2)
    let card = Card.mock()
    let other = Card.mock(id: UUID())

    await #expect(throws: URLError.self) { try await client.history(for: card) }
    await #expect(throws: URLError.self) { try await client.history(for: card) }
    await #expect(throws: URLError.self) { try await client.history(for: other) }
    #expect(try await client.history(for: card).series.isEmpty == false)
  }
}
