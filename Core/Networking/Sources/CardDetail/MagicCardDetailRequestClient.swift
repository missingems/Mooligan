import ScryfallKit

public protocol MagicCardDetailRequestClient {
  associatedtype MagicCardModel: MagicCard
  func getVariants(of card: MagicCardModel, page: Int) async throws -> [MagicCardModel]
}

extension ScryfallClient: MagicCardDetailRequestClient {
  public func getVariants(of card: MagicCardModel, page: Int) async throws -> [MagicCardModel] {
    try await searchCards(
      filters: [.name(card.name), .game(.paper)],
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
