public protocol BrowseRequestClient {
  associatedtype Model: GameSet
  func getAllSets() async throws -> [Model]
}
