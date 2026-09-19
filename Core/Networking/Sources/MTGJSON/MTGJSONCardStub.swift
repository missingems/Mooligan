import Foundation
import ScryfallKit

struct MTGJSONCardStub: Decodable {
  struct Identifiers: Decodable {
    let scryfallId: String?
  }

  let uuid: String
  let rarity: Card.Rarity?
  /// MTGJSON keys its sheets by its own uuid; the app knows cards by their
  /// Scryfall id, so the two have to be joined here.
  let identifiers: Identifiers?
}
