#if DEBUG
import Foundation
import ScryfallKit

public struct MockGameSetRequestClient: GameSetRequestClient {
  public init() {}

  public func getSets(
    queryType: GameSetQueryType
  ) async throws -> ([ScryfallClient.SetsSection], [MTGSet]) {
    switch queryType {
    case .all:
      return (Self.mocksSetSections, Self.mockSets)

    case let .name(query, _):
      let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
      guard trimmed.isEmpty == false else {
        return (Self.mocksSetSections, Self.mockSets)
      }
      let matches = Self.mockSets.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
      let sections = [
        ScryfallClient.SetsSection(isUpcomingSet: false, displayDate: "Results", sets: matches),
      ]
      return (sections, matches)
    }
  }

  public static let mockSets: [MTGSet] = [
    MTGSet(
      id: UUID(), code: "FIN", mtgoCode: nil, tcgplayerId: 0,
      name: "Final Fantasy", setType: .alchemy, releasedAt: "2025-06-13",
      blockCode: "FIN", block: "Universes Beyond", parentSetCode: nil,
      cardCount: 309, printedSize: 309, digital: false,
      foilOnly: false, nonfoilOnly: false,
      scryfallUri: "https://scryfall.com/sets/fin",
      uri: "https://api.scryfall.com/sets/fin",
      iconSvgUri: "https://img.scryfall.com/sets/fin.svg",
      searchUri: "https://api.scryfall.com/cards/search?order=set&q=e%3Afin"
    ),
    MTGSet(
      id: UUID(), code: "TDM", mtgoCode: nil, tcgplayerId: 0,
      name: "Tarkir: Dragonstorm", setType: .expansion, releasedAt: "2025-04-11",
      blockCode: "TDM", block: "Tarkir Cycle", parentSetCode: nil,
      cardCount: 286, printedSize: 286, digital: false,
      foilOnly: false, nonfoilOnly: false,
      scryfallUri: "https://scryfall.com/sets/tdm",
      uri: "https://api.scryfall.com/sets/tdm",
      iconSvgUri: "https://img.scryfall.com/sets/tdm.svg",
      searchUri: "https://api.scryfall.com/cards/search?order=set&q=e%3Atdm"
    ),
    MTGSet(
      id: UUID(), code: "MKM", mtgoCode: nil, tcgplayerId: 0,
      name: "Murders at Karlov Manor", setType: .expansion, releasedAt: "2024-02-09",
      blockCode: "MKM", block: "Ravnica", parentSetCode: nil,
      cardCount: 286, printedSize: 286, digital: false,
      foilOnly: false, nonfoilOnly: false,
      scryfallUri: "https://scryfall.com/sets/mkm",
      uri: "https://api.scryfall.com/sets/mkm",
      iconSvgUri: "https://img.scryfall.com/sets/mkm.svg",
      searchUri: "https://api.scryfall.com/cards/search?order=set&q=e%3Amkm"
    ),
    MTGSet(
      id: UUID(), code: "WOE", mtgoCode: nil, tcgplayerId: 0,
      name: "Wilds of Eldraine", setType: .expansion, releasedAt: "2023-09-08",
      blockCode: "WOE", block: "Eldraine Cycle", parentSetCode: nil,
      cardCount: 381, printedSize: 381, digital: false,
      foilOnly: false, nonfoilOnly: false,
      scryfallUri: "https://scryfall.com/sets/woe",
      uri: "https://api.scryfall.com/sets/woe",
      iconSvgUri: "https://img.scryfall.com/sets/woe.svg",
      searchUri: "https://api.scryfall.com/cards/search?order=set&q=e%3Awoe"
    ),
    MTGSet(
      id: UUID(), code: "LHIC", mtgoCode: nil, tcgplayerId: 0,
      name: "The Lost Caverns of Ixalan", setType: .expansion, releasedAt: "2023-11-17",
      blockCode: "LCI", block: "Ixalan Cycle", parentSetCode: nil,
      cardCount: 291, printedSize: 291, digital: false,
      foilOnly: false, nonfoilOnly: false,
      scryfallUri: "https://scryfall.com/sets/lci",
      uri: "https://api.scryfall.com/sets/lci",
      iconSvgUri: "https://img.scryfall.com/sets/lci.svg",
      searchUri: "https://api.scryfall.com/cards/search?order=set&q=e%3Alci"
    )
  ]

  nonisolated(unsafe) public static let mocksSetSections: [ScryfallClient.SetsSection] = [
    .init(isUpcomingSet: true, displayDate: "Latest", sets: Array(mockSets.prefix(2))),
    .init(isUpcomingSet: true, displayDate: "Older", sets: Array(mockSets.suffix(3))),
    .init(isUpcomingSet: false, displayDate: "Older", sets: Array(mockSets.suffix(3))),
    .init(isUpcomingSet: false, displayDate: "Older", sets: Array(mockSets.suffix(3))),
  ]
}
#endif
