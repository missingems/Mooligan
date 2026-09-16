import Foundation
import Networking

extension PriceProvider {
  /// The vendor's buylist search for a card by name, for the vendors that publish their buylist on
  /// the web. The price feed carries no per-printing buylist link, so a name search is the closest
  /// page to send someone to.
  func buylistURL(forCardNamed name: String) -> URL? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.isEmpty == false else { return nil }

    switch self {
    case .cardkingdom:
      var components = URLComponents()
      components.scheme = "https"
      components.host = "www.cardkingdom.com"
      components.path = "/purchasing/mtg_singles"
      components.queryItems = [
        URLQueryItem(name: "filter[search]", value: "mtg_advanced"),
        URLQueryItem(name: "filter[name]", value: trimmed),
      ]
      return components.url

    case .tcgplayer, .cardmarket, .cardsphere, .cardhoarder:
      return nil
    }
  }
}
