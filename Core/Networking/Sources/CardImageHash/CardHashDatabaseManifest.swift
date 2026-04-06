public struct CardHashDatabaseManifest: Codable, Sendable {
  public let masterVersion: Int
  public let masterChunks: Int
  public let latestPatch: Int
}
