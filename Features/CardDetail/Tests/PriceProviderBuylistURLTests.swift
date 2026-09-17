@testable import CardDetail
import Foundation
import Networking
import Testing

struct PriceProviderBuylistURLTests {
  @Test func cardKingdomShouldSearchItsBuylistByName() throws {
    let url = try #require(PriceProvider.cardkingdom.buylistURL(forCardNamed: "Lightning Bolt"))
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

    #expect(components.scheme == "https")
    #expect(components.host == "www.cardkingdom.com")
    #expect(components.path == "/purchasing/mtg_singles")
    #expect(components.queryItems?.first { $0.name == "filter[search]" }?.value == "mtg_advanced")
    #expect(components.queryItems?.first { $0.name == "filter[name]" }?.value == "Lightning Bolt")
  }

  @Test func namesShouldBeQueryEncoded() throws {
    let url = try #require(PriceProvider.cardkingdom.buylistURL(forCardNamed: "Jace's Ingenuity & Co"))

    #expect(url.absoluteString.contains(" ") == false)
    #expect(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.last?.value == "Jace's Ingenuity & Co")
  }

  @Test(arguments: ["", "   "])
  func withoutANameThereShouldBeNoLink(name: String) {
    #expect(PriceProvider.cardkingdom.buylistURL(forCardNamed: name) == nil)
  }

  @Test(arguments: [PriceProvider.tcgplayer, .cardmarket, .cardsphere, .cardhoarder])
  func vendorsWithoutAWebBuylistShouldHaveNoLink(provider: PriceProvider) {
    #expect(provider.buylistURL(forCardNamed: "Lightning Bolt") == nil)
  }
}
