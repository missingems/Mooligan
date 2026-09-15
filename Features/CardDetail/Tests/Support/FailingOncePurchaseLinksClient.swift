@testable import CardDetail
import Foundation
import Networking
import ScryfallKit

actor FailingOncePurchaseLinksClient: PurchaseLinksClient {
  static let urls = MTGGraphQLPurchaseUrls(tcgplayer: "https://mtgjson.com/links/tcg")
  private var calls = 0

  func purchaseLinks(for card: Card) async throws -> [PurchaseLink] {
    calls += 1
    if calls == 1 {
      throw URLError(.notConnectedToInternet)
    }
    return PurchaseLinksMapper.makeLinks(from: Self.urls)
  }
}
