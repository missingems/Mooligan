struct MockBrowseRequestClient: BrowseRequestClient {
  func getAllSets() async throws -> [any Set] {
    return []
  }
}
