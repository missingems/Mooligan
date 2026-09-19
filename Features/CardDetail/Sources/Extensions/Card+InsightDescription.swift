import Foundation
import Networking
import ScryfallKit

extension Card {
  /// Everything about the card the on-device model is given to write from, one fact to a line.
  ///
  /// The model knows little about Magic and less about this card, so it is told all of it: what it
  /// is not told, it is asked not to mention.
  var insightDescription: String {
    var lines = ["Name: \(name)"]

    if let faces = cardFaces, faces.count > 1 {
      for (index, face) in faces.enumerated() {
        lines.append("Face \(index + 1): \(face.name)")
        if face.manaCost.isEmpty == false { lines.append("  Mana cost: \(face.manaCost)") }
        if let typeLine = face.typeLine { lines.append("  Type: \(typeLine)") }
        if let text = face.oracleText, text.isEmpty == false { lines.append("  Rules text: \(text)") }
        if let power = face.power, let toughness = face.toughness {
          lines.append("  Power/toughness: \(power)/\(toughness)")
        }
        if let loyalty = face.loyalty { lines.append("  Starting loyalty: \(loyalty)") }
      }
    } else {
      if let manaCost, manaCost.isEmpty == false { lines.append("Mana cost: \(manaCost)") }
      if let typeLine { lines.append("Type: \(typeLine)") }
      if let oracleText, oracleText.isEmpty == false { lines.append("Rules text: \(oracleText)") }
      if let power, let toughness { lines.append("Power/toughness: \(power)/\(toughness)") }
      if let loyalty { lines.append("Starting loyalty: \(loyalty)") }
    }

    if let cmc { lines.append("Mana value: \(cmc.formatted())") }
    if let colors { lines.append("Colors: \(colors.isEmpty ? "colorless" : colors.map(\.name).joined(separator: ", "))") }
    lines.append("Color identity: \(colorIdentity.isEmpty ? "colorless" : colorIdentity.map(\.name).joined(separator: ", "))")
    lines.append("Set: \(setName) (\(set.uppercased())), released \(releasedAt)")
    lines.append("Collector number: \(collectorNumber)")
    lines.append("Rarity: \(rarity.rawValue)")
    if treatments.isEmpty == false { lines.append("Printing: \(treatments.joined(separator: ", "))") }

    // Grouped by status, leaving out the formats it is not legal in, which is most of them for most
    // cards and says nothing.
    let legalities = Dictionary(grouping: legalities.all, by: \.value)
    for status in [MagicCardLegality.legal, .restricted, .banned] {
      guard let formats = legalities[status.label], formats.isEmpty == false else { continue }
      lines.append("\(status.label) in: \(formats.map(\.title).joined(separator: ", "))")
    }

    let prices = [prices.usd.map { "$\($0)" }, prices.usdFoil.map { "$\($0) foil" }].compactMap(\.self)
    if prices.isEmpty == false { lines.append("Market price: \(prices.joined(separator: ", "))") }

    return lines.joined(separator: "\n")
  }
}
