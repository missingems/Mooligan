import ComposableArchitecture
import ScryfallKit

public protocol MagicCardDetailRequestClient: Sendable {
  func getRulings(of card: Card) async throws -> [MagicCardRuling]
  func getVariants(of card: Card, page: Int) async throws -> [Card]
  func getSet(of card: Card) async throws -> MTGSet
}

public enum CardDetailRequestClientKey: DependencyKey {
  public static let liveValue: any MagicCardDetailRequestClient = ScryfallClient()
  public static let previewValue: any MagicCardDetailRequestClient = ScryfallClient()
  public static let testValue: any MagicCardDetailRequestClient = ScryfallClient()
}

extension ScryfallClient: MagicCardDetailRequestClient {
  public func getRulings(of card: Card) async throws -> [MagicCardRuling] {
    try await getRulings(.scryfallID(id: card.id.uuidString)).data.reversed().map { value in
      MagicCardRuling(
        displayDate: value.publishedAt,
        description: value.comment.split(separator: "\n").map {
          TextElementParser.parse(String($0))
        }
      )
    }
  }
  
  public func getVariants(of card: Card, page: Int) async throws -> [Card] {
    guard let oracleID = card.oracleId else {
      throw MagicCardDetailRequestClientError.cardOracleIDIsNil
    }
    
    let cards = try await searchCards(
      filters: [.oracleId(oracleID), .game(.paper)],
      unique: .prints,
      order: nil,
      sortDirection: nil,
      includeExtras: true,
      includeMultilingual: false,
      includeVariations: true,
      page: page
    ).data
    
    if cards.isEmpty {
      return [card]
    } else {
      return cards
    }
  }
  
  public func getSet(of card: Card) async throws -> MTGSet {
    try await getSet(identifier: .code(code: card.set))
  }
}

public extension DependencyValues {
  var cardDetailRequestClient: any MagicCardDetailRequestClient {
    get { self[CardDetailRequestClientKey.self] }
    set { self[CardDetailRequestClientKey.self] = newValue }
  }
}

public enum MagicCardDetailRequestClientError: Error {
  case cardOracleIDIsNil
}
