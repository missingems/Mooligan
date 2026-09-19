import Foundation

extension MTGJSONSetData {
  /// The chance of opening each card in each of this set's products, read straight off the sheets
  /// Wizards prints the packs from.
  ///
  /// A product comes in several pack layouts, each taking a number of cards from a number of
  /// sheets, and each with its own share of the packs printed. A card's chance in one layout is the
  /// chance that any of the sheets it sits on gives it up; its chance in the product is those,
  /// weighted by how often each layout is printed. That is the whole configuration, rather than the
  /// three numbers the pack roller keeps, so showcase printings and the Collector Booster's own
  /// sheets come out at their real odds too.
  ///
  /// Digital products (MTG Arena's) and Collector Sample Boosters are left out: neither is a pack
  /// anyone can buy and open.
  func pullOdds(setCode: String) -> SetPullOdds {
    let uuids = Dictionary(
      cards.compactMap { card in card.identifiers?.scryfallId.map { ($0.lowercased(), card.uuid) } },
      uniquingKeysWith: { first, _ in first }
    )

    var odds: [String: [ProductPullOdds]] = [:]
    var products: [String: String] = [:]
    for (key, config) in booster ?? [:] {
      guard ["arena", "mtgo", "sample"].contains(where: { key.contains($0) }) == false else { continue }

      let productName = productName(of: config, key: key)
      products["\(setCode.lowercased())/\(key)"] = productName
      for (uuid, chances) in config.chances() {
        odds[uuid, default: []].append(ProductPullOdds(
          id: "\(setCode.lowercased())/\(key)",
          name: productName,
          setName: name ?? setCode.uppercased(),
          chance: chances.any,
          foilChance: chances.foil,
          nonFoilChance: chances.nonFoil
        ))
      }
    }

    return SetPullOdds(uuidsByScryfallID: uuids, oddsByUUID: odds, products: products)
  }

  /// "Bloomburrow Play Booster" is quoted as "Play Booster": the set is already on screen.
  private func productName(of config: MTGJSONBoosterConfig, key: String) -> String {
    guard let full = config.name else {
      return key.split(separator: "-").map(\.capitalized).joined(separator: " ") + " Booster"
    }
    guard let name, full.hasPrefix(name), full.count > name.count else { return full }
    return full.dropFirst(name.count).trimmingCharacters(in: .whitespaces)
  }
}
