import ScryfallKit

public protocol MagicCardDetailRequestClient: Sendable {
  associatedtype MagicCardModel: MagicCard
  associatedtype MagicCardSet: GameSet
  
  func getRulings(of card: MagicCardModel) async throws -> [MagicCardRuling]
  func getVariants(of card: MagicCardModel, page: Int) async throws -> [MagicCardModel]
  func getSet(of card: MagicCardModel) async throws -> MagicCardSet
}

extension ScryfallClient: MagicCardDetailRequestClient {
  public func getRulings(of card: MagicCardModel) async throws -> [MagicCardRuling] {
    try await getRulings(.scryfallID(id: card.id.uuidString)).data.map { value in
      MagicCardRuling(displayDate: value.publishedAt, description: value.comment)
    }
  }
  
  public func getVariants(of card: MagicCardModel, page: Int) async throws -> [MagicCardModel] {
    guard let oracleID = card.getOracleID() else {
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
  
  public func getSet(of card: Card) async throws -> some GameSet {
    try await getSet(identifier: .code(code: card.set))
  }
}

public enum MagicCardDetailRequestClientError: Error {
  case cardOracleIDIsNil
}
