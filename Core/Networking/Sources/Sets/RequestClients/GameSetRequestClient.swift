public protocol GameSetRequestClient: Sendable {
  associatedtype GameSetModel: GameSet
  func getAllSets() async throws -> [GameSetModel]
}
