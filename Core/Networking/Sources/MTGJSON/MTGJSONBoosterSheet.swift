import Foundation

struct MTGJSONBoosterSheet: Decodable {
  /// Card uuid to its weight within this sheet.
  let cards: [String: Double]
  let foil: Bool
  /// The sum of `cards`' weights, as MTGJSON writes it out.
  let totalWeight: Double?
  /// Whether one pack can take the same card from this sheet twice. Absent
  /// means it cannot.
  let allowDuplicates: Bool?
}
