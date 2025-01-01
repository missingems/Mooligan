import Foundation
import ScryfallKit

public extension Card {
  static var mock: Self {
    Card(
      id: UUID(),
      oracleId: "1",
      lang: "en",
      printsSearchUri: "",
      rulingsUri: "",
      scryfallUri: "",
      uri: "",
      cmc: 0,
      colorIdentity: [],
      keywords: [],
      layout: .normal,
      legalities: .init(
        standard: nil,
        historic: nil,
        pioneer: nil,
        modern: nil,
        legacy: nil,
        pauper: nil,
        vintage: nil,
        penny: nil,
        commander: nil,
        brawl: nil
      ),
      name: "",
      oversized: false,
      reserved: false,
      booster: false,
      borderColor: .black,
      collectorNumber: "",
      digital: false,
      finishes: [],
      frame: .future,
      fullArt: false,
      games: [],
      highresImage: false,
      imageStatus: .highresScan,
      imageUris: .init(
        small: "https://google.com",
        normal: "https://google.com",
        large: "https://google.com",
        png: "https://google.com",
        artCrop: "https://google.com",
        borderCrop: "https://google.com"
      ),
      prices: .init(
        tix: nil,
        usd: "1",
        usdFoil: "1",
        eur: "1"
      ),
      promo: false,
      rarity: .bonus,
      relatedUris: [:],
      releasedAt: "1",
      reprint: false,
      scryfallSetUri: "",
      setName: "",
      setSearchUri: URL.init(
        string: "https://google.com"
      )!,
      setType: .alchemy,
      setUri: "",
      set: "",
      storySpotlight: false,
      textless: false,
      variation: false
    )
  }
}

public struct MockCardDetailRequestClient: MagicCardDetailRequestClient {
  public static func generateMockCards(number: Int) -> [Card] {
    var cards: [Card] = []
    for _ in 0...number {
      cards.append(.mock)
    }
    
    return cards
  }
  
  public func getRulings(
    of card: Card
  ) async throws -> [MagicCardRuling] {
    [
      MagicCardRuling(
        displayDate: "12-10-1992",
        description: [
          [
            .text(
              "italic",
              isItalic: true,
              isKeyword: false
            ),
            .text(
              "normal",
              isItalic: false,
              isKeyword: false
            ),
            .text(
              "keyword",
              isItalic: false,
              isKeyword: true
            ),
          ]
        ]
      )
    ]
  }
  
  public func getVariants(
    of card: Card,
    page: Int
  ) async throws -> [Card] {
    Self.generateMockCards(number: 10)
  }
  
  public func getSet(
    of card: Card
  ) async throws -> MTGSet {
    MTGSet(
      id: UUID(),
      code: "FDN",
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
  }
}
