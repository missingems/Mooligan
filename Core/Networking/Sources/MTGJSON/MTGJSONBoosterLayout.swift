import Foundation

/// One way a product's pack is put together.
struct MTGJSONBoosterLayout: Decodable {
  /// Sheet name to the number of cards the pack takes from that sheet.
  let contents: [String: Int]
  let weight: Double
}
