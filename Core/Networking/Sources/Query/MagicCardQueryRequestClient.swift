import ScryfallKit

public protocol MagicCardQueryRequestClient: Sendable {
  func queryCards(_ query: QueryType) async throws -> ObjectList<[Card]>
}

extension ScryfallClient: MagicCardQueryRequestClient {
  public func queryCards(_ query: QueryType) async throws -> ObjectList<[Card]> {
    switch query {
    case let .search(text, page):
      let result = try await searchCards(
        query: text,
        unique: .prints,
        order: nil,
        sortDirection: nil,
        includeExtras: true,
        includeMultilingual: false,
        includeVariations: true,
        page: page
      )
      
      return ObjectList(model: result.data, hasNextPage: result.hasMore ?? false)
      
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
      
      return ObjectList(model: result.data, hasNextPage: result.hasMore ?? false)
    }
  }
}
