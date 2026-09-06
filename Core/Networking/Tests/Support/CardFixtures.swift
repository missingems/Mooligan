import Foundation
import ScryfallKit

enum CardFixtures {
  static func card(
    id: UUID = UUID(),
    name: String = "Lightning Bolt",
    setCode: String = "fdn",
    collectorNumber: String = "1",
    rarity: Card.Rarity = .common,
    cmc: Double = 1,
    colorIdentity: [Card.Color] = [.R],
    typeLine: String? = "Instant",
    releasedAt: String = "2024-11-15",
    usd: String? = "1.00",
    games: [Game] = [.paper],
    isDigital: Bool = false,
    oracleID: String? = "aaaaaaaa-0000-4000-8000-000000000001"
  ) -> Card {
    var card = Card.mock(id: id)
    card.name = name
    card.set = setCode
    card.setName = setCode.uppercased()
    card.collectorNumber = collectorNumber
    card.rarity = rarity
    card.cmc = cmc
    card.colorIdentity = colorIdentity
    card.typeLine = typeLine
    card.releasedAt = releasedAt
    card.prices = Card.Prices(usd: usd)
    card.games = games
    card.digital = isDigital
    card.oracleId = oracleID
    return card
  }

  static func set(
    code: String,
    count: Int,
    names: [String]? = nil
  ) -> [Card] {
    (1...count).map { index in
      card(
        name: names?[index - 1] ?? "Card \(index)",
        setCode: code,
        collectorNumber: "\(index)"
      )
    }
  }
}
