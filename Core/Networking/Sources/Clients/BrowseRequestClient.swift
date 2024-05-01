public protocol BrowseRequestClient {
  func getAllSets() async throws -> [any GameSet]
}
