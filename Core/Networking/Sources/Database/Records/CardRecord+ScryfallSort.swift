import Foundation
import ScryfallKit

/// The keys a set is sorted on when it is browsed from the catalog, worked out so the order is the
/// one Scryfall gives the same query. A pull to refresh swaps the catalog's page for Scryfall's, so
/// any difference between the two shows up as cards jumping around.
extension CardRecord {
  /// Scryfall compares names by their letters and digits alone, ignoring case, accents, spaces and
  /// punctuation: "Kastral, the Windcrested" sorts as "kastralthewindcrested".
  static func sortName(_ name: String) -> String {
    let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
    return String(String.UnicodeScalarView(folded.unicodeScalars.filter {
      $0.isASCII && CharacterSet.alphanumerics.contains($0)
    }))
  }

  /// Scryfall's colour order: coloured cards by their colours (the five, then the guilds, shards,
  /// wedges, four colours and all five), then colourless spells, then lands. Colourless spells and
  /// lands are grouped by colour identity the same way, with no identity last.
  static func colorRank(for card: Card) -> Int {
    let colors = (card.colors ?? card.cardFaces?.first?.colors ?? []).filter { $0 != .C }
    guard colors.isEmpty else { return combinationRank(colors) }

    let typeLine = card.cardFaces?.first?.typeLine ?? card.typeLine ?? ""
    let identity = card.colorIdentity.filter { $0 != .C }
    return (typeLine.contains("Land") ? 200 : 100) + combinationRank(identity)
  }

  private static func combinationRank(_ colors: [Card.Color]) -> Int {
    let order: [Set<Card.Color>] = [
      [.W], [.U], [.B], [.R], [.G],
      // The guilds, in Ravnica's order.
      [.W, .U], [.U, .B], [.B, .R], [.R, .G], [.G, .W],
      [.W, .B], [.U, .R], [.B, .G], [.R, .W], [.G, .U],
      // The shards, then the wedges.
      [.W, .U, .B], [.U, .B, .R], [.B, .R, .G], [.R, .G, .W], [.G, .W, .U],
      [.W, .B, .G], [.U, .R, .W], [.B, .G, .U], [.R, .W, .B], [.G, .U, .R],
      // Four colours, named by the one missing: G, W, U, B, R.
      [.W, .U, .B, .R], [.U, .B, .R, .G], [.W, .B, .R, .G], [.W, .U, .R, .G], [.W, .U, .B, .G],
      [.W, .U, .B, .R, .G],
    ]
    return colors.isEmpty ? 32 : 1 + (order.firstIndex(of: Set(colors)) ?? 31)
  }
}
