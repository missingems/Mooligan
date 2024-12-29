import Foundation
import ScryfallKit

public struct MockGameSetRequestClient: GameSetRequestClient {
  public func getAllSets() async throws -> [MTGSet] {
    [
      MTGSet(
        id: UUID(),
        code: "123",
        mtgoCode: "123",
        tcgplayerId: 1,
        name: "Test Set",
        setType: .alchemy,
        releasedAt: "19-10-1992",
        blockCode: "123",
        block: "123",
        parentSetCode: nil,
        cardCount: 10,
        printedSize: 10,
        digital: true,
        foilOnly: false,
        nonfoilOnly: false,
        scryfallUri: "scryfalURI",
        uri: "uri",
        iconSvgUri: "iconSVGURI",
        searchUri: "searchURI"
      ),
      MTGSet(
        id: UUID(),
        code: "123",
        mtgoCode: "123",
        tcgplayerId: 1,
        name: "Test Set",
        setType: .alchemy,
        releasedAt: "19-10-1992",
        blockCode: "123",
        block: "123",
        parentSetCode: nil,
        cardCount: 10,
        printedSize: 10,
        digital: true,
        foilOnly: false,
        nonfoilOnly: false,
        scryfallUri: "scryfalURI",
        uri: "uri",
        iconSvgUri: "iconSVGURI",
        searchUri: "searchURI"
      ),
      MTGSet(
        id: UUID(),
        code: "123",
        mtgoCode: "123",
        tcgplayerId: 1,
        name: "Test Set",
        setType: .alchemy,
        releasedAt: "19-10-1992",
        blockCode: "123",
        block: "123",
        parentSetCode: nil,
        cardCount: 10,
        printedSize: 10,
        digital: true,
        foilOnly: false,
        nonfoilOnly: false,
        scryfallUri: "scryfalURI",
        uri: "uri",
        iconSvgUri: "iconSVGURI",
        searchUri: "searchURI"
      ),
      MTGSet(
        id: UUID(),
        code: "123",
        mtgoCode: "123",
        tcgplayerId: 1,
        name: "Test Set",
        setType: .alchemy,
        releasedAt: "19-10-1992",
        blockCode: "123",
        block: "123",
        parentSetCode: nil,
        cardCount: 10,
        printedSize: 10,
        digital: true,
        foilOnly: false,
        nonfoilOnly: false,
        scryfallUri: "scryfalURI",
        uri: "uri",
        iconSvgUri: "iconSVGURI",
        searchUri: "searchURI"
      ),
      MTGSet(
        id: UUID(),
        code: "123",
        mtgoCode: "123",
        tcgplayerId: 1,
        name: "Test Set",
        setType: .alchemy,
        releasedAt: "19-10-1992",
        blockCode: "123",
        block: "123",
        parentSetCode: nil,
        cardCount: 10,
        printedSize: 10,
        digital: true,
        foilOnly: false,
        nonfoilOnly: false,
        scryfallUri: "scryfalURI",
        uri: "uri",
        iconSvgUri: "iconSVGURI",
        searchUri: "searchURI"
      )
    ]
  }
}
