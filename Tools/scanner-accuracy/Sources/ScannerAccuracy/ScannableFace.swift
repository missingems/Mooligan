import Foundation

/// A face of a printing as the scanner's database stores it.
struct ScannableFace: Codable, Hashable, Sendable {
  /// The card id, or `<card id>-face<index>` for a card whose faces have their own images.
  let faceID: String
  let name: String
  let set: String
  let collectorNumber: String
  let imageURL: URL?
  let oracleID: String?
  let illustrationID: String?

  var label: String { "\(name) (\(set.uppercased()) #\(collectorNumber))" }
}
