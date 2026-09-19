import Foundation

/// MTGJSON's `Meta.json`: the build the files on the server were made by.
struct MTGJSONMetaFile: Decodable {
  struct Meta: Decodable {
    let version: String?
  }

  let data: Meta
}
