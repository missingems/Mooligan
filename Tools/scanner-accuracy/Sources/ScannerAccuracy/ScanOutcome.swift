/// What the scanner made of one frame.
struct ScanOutcome: Sendable {
  let niche: String
  let environment: SimulatedEnvironment
  let expected: ScannableFace
  /// How far the detected corners are from the card's, as a fraction of its
  /// height; nil when no card was found.
  let cornerError: Double?
  /// The best match, or nil when nothing was within the scanner's threshold.
  let match: MatchResult?

  /// Found and cropped close enough to recognise: within 3% of the card's height.
  var isDetected: Bool { cornerError.map { $0 < 0.03 } ?? false }
}
