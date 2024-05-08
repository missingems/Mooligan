import ScryfallKit

public protocol MagicCardQueryRequestClient {
  func queryCards(_ query: MagicCardQueryType) async throws -> [any MagicCard]
}
