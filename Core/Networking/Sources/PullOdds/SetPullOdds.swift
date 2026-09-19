import Foundation

/// Everything one MTGJSON set file says about pull odds, worked out once so the
/// file is downloaded and read once.
struct SetPullOdds: Equatable, Sendable, Codable {
  /// Lowercased Scryfall id to MTGJSON's uuid, for the set's own cards. A card's
  /// odds can live in another set's products, which know it only by the uuid.
  let uuidsByScryfallID: [String: String]
  /// MTGJSON uuid to every product of this set that can hold that card. That
  /// includes other sets' cards the products draw from, such as a commander
  /// deck's cards in the set's Collector Booster.
  let oddsByUUID: [String: [ProductPullOdds]]
  /// Every product of the set sold as packs, id to name, whether it holds a given card or not: the
  /// mix a card's estimate is worked out over.
  let products: [String: String]

  static let empty = SetPullOdds(uuidsByScryfallID: [:], oddsByUUID: [:], products: [:])
}
