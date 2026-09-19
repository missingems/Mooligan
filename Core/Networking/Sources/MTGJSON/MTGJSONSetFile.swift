import Foundation

/// One set's file from MTGJSON, `https://mtgjson.com/api/v5/<CODE>.json`.
struct MTGJSONSetFile: Decodable {
  let data: MTGJSONSetData
}
