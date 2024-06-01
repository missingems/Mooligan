import ScryfallKit

public protocol MagicCardDetailRequestClient {
  associatedtype MagicCardModel: MagicCard
  func getVariants(of card: MagicCardModel, page: Int) async throws -> [MagicCardModel]
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
}
