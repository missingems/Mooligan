public protocol GameSetRequestClient {
  associatedtype GameSetModel: GameSet
  func getAllSets() async throws -> [GameSetModel]
}
