import ScryfallKit

public protocol MagicCardQueryRequestClient {
  associatedtype MagicCardModel: MagicCard
  func queryCards(_ query: QueryType) async throws -> [MagicCardModel]
}
