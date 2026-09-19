import Foundation
import Networking
import ScryfallKit

/// One tile of the card's information row: what it shows, and what tapping it explains.
enum InformationWidget: Hashable, Sendable {
  case set(code: String, rarity: Card.Rarity, iconURL: URL?)
  /// `tilt` is the degrees its sticker leans, which differ from card to card.
  case pullOdds(CardPullOdds, rarity: Card.Rarity, tilt: Double)
  case collectorNumber(String)
  case colorIdentity([String])
  case manaValue(String)
  case loyalty(counters: String)
  case powerToughness(power: String, toughness: String)

  /// A name for the tile that does not change with what it shows, for accessibility identifiers.
  var name: String {
    switch self {
    case .set: "set"
    case .pullOdds: "pullOdds"
    case .collectorNumber: "collectorNumber"
    case .colorIdentity: "colorIdentity"
    case .manaValue: "manaValue"
    case .loyalty: "loyalty"
    case .powerToughness: "powerToughness"
    }
  }
}
