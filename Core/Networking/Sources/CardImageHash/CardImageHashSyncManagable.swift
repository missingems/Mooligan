import CoreGraphics

public protocol CardImageHashSyncManagable: Sendable {
  func sync() async
  func findBestMatches(for image: CGImage) async -> [MatchResult]
}
