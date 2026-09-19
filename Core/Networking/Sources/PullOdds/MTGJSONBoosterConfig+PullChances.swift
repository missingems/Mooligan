import Foundation

extension MTGJSONBoosterConfig {
  /// Card uuid to its chance of turning up in one pack of this product: in any finish, as a foil,
  /// and not as one.
  ///
  /// Within one sheet a pack takes `count` cards. When the sheet cannot repeat a card, the chance of
  /// a card of weight `w` out of `total` is `count × w / total`, which is exact for evenly weighted
  /// sheets and within a hair of it for the rest. When it can, it is `1 − (1 − w / total)^count`.
  /// Sheets are drawn independently of one another, so a card on several of them is missed only if
  /// every one of them misses it.
  func chances() -> [String: (any: Double, foil: Double, nonFoil: Double)] {
    guard let boosters else { return [:] }
    let totalWeight = boostersTotalWeight ?? boosters.reduce(0) { $0 + $1.weight }
    guard totalWeight > 0 else { return [:] }

    var chances: [String: (any: Double, foil: Double, nonFoil: Double)] = [:]
    for layout in boosters where layout.weight > 0 {
      var foilMiss: [String: Double] = [:]
      var nonFoilMiss: [String: Double] = [:]

      for (sheetName, count) in layout.contents where count > 0 {
        guard let sheet = sheets[sheetName] else { continue }
        let sheetWeight = sheet.totalWeight ?? sheet.cards.values.reduce(0, +)
        guard sheetWeight > 0 else { continue }

        for (uuid, weight) in sheet.cards where weight > 0 {
          let share = weight / sheetWeight
          let hit = sheet.allowDuplicates == true
            ? 1 - pow(1 - share, Double(count))
            : min(1, Double(count) * share)
          if sheet.foil {
            foilMiss[uuid, default: 1] *= 1 - hit
          } else {
            nonFoilMiss[uuid, default: 1] *= 1 - hit
          }
        }
      }

      let layoutShare = layout.weight / totalWeight
      for uuid in Set(foilMiss.keys).union(nonFoilMiss.keys) {
        let foil = foilMiss[uuid] ?? 1
        let nonFoil = nonFoilMiss[uuid] ?? 1
        var chance = chances[uuid] ?? (0, 0, 0)
        chance.any += layoutShare * (1 - foil * nonFoil)
        chance.foil += layoutShare * (1 - foil)
        chance.nonFoil += layoutShare * (1 - nonFoil)
        chances[uuid] = chance
      }
    }

    return chances.filter { $0.value.any > 0 }
  }
}
