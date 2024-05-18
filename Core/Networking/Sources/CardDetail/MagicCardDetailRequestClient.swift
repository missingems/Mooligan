import ScryfallKit

public protocol MagicCardDetailRequestClient {
  associatedtype MagicCardModel: MagicCard
  func getVariants(_ query: MagicCardModel) async throws -> [MagicCardModel]
}
