/// `manifest.json` published by github.com/missingems/MTGImageHash.
public struct CardHashDatabaseManifest: Codable, Equatable, Sendable {
  /// Changes when the server rebases; the client must then re-download the master.
  public let masterVersion: String
  public let masterChunks: Int
  /// Number of `patch_<n>.lzfse` files on top of the current master.
  public let latestPatch: Int
}
