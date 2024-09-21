import ScryfallKit

public protocol MagicCardQueryRequestClient: Sendable {
  associatedtype MagicCardModel: MagicCard
  func queryCards(_ query: QueryType) async throws -> ObjectList<[MagicCardModel]>
}
