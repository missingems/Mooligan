public protocol GameSetRequestClient {
  associatedtype Model: GameSet
  func getAllSets() async throws -> [Model]
}
