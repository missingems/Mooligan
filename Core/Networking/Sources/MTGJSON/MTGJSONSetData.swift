import Foundation

/// Deliberately minimal: only the fields the app reads out of a multi-megabyte
/// file. `Decodable` still has to tokenize the rest of each card's JSON to skip
/// it, but decodes no Swift representation for any field beyond these.
struct MTGJSONSetData: Decodable {
  /// The set's name, which MTGJSON also opens every product's name with.
  let name: String?
  let booster: [String: MTGJSONBoosterConfig]?
  let cards: [MTGJSONCardStub]
}
