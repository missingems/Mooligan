public protocol MTGQueryRequestClient {
  func fetchCards() async throws -> [any MTGCard]
}
