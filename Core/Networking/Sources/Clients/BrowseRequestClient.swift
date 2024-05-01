public protocol BrowseRequestClient {
  func getAllSets() async throws -> [Set]
}
