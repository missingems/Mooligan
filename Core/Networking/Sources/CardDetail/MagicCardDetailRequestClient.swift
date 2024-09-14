import ScryfallKit

public protocol MagicCardDetailRequestClient: Sendable {
  associatedtype MagicCardModel: MagicCard
  associatedtype MagicCardSet: GameSet
  
  func getVariants(of card: MagicCardModel, page: Int) async throws -> [MagicCardModel]
  func getSet(of card: MagicCardModel) async throws -> MagicCardSet
}

extension ScryfallClient: MagicCardDetailRequestClient {
  public func getVariants(of card: MagicCardModel, page: Int) async throws -> [MagicCardModel] {
    guard let oracleID = card.getOracleID() else { return [] }
    
    return try await searchCards(
      filters: [.oracleId(oracleID), .game(.paper)],
      unique: .prints,
      order: nil,
      sortDirection: nil,
      includeExtras: true,
      includeMultilingual: false,
      includeVariations: true,
      page: page
    )
    .data
  }
  
  public func getSet(of card: Card) async throws -> some GameSet {
    try await getSet(identifier: .code(code: card.set))
  }
}
