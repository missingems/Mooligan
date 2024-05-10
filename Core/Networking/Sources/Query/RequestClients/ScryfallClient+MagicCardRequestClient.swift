import ScryfallKit

extension ScryfallClient: MagicCardQueryRequestClient {
  public func queryCards(_ query: QueryType) async throws -> [Card] {
    switch query {
    case .search:
      return []
      
    case let .set(gameSet, page):
      let result = try await searchCards(
        filters: [.set(gameSet.code)],
        unique: .prints,
        order: nil,
        sortDirection: nil,
        includeExtras: true,
        includeMultilingual: false,
        includeVariations: true,
        page: page
      )
      
      
      return result.data
    }
  }
}
