#if DEBUG
import Foundation

/// Writes fixed text with no model. Used by previews and `-uiTestMode`; tests pass the snapshots
/// they want, or nil for a device without Apple Intelligence.
public struct MockCardInsightWriter: CardInsightWriter {
  private let snapshots: [String]?

  public init(snapshots: [String]? = [
    "On this card,",
    "On this card, the detail you tapped is explained in a couple of short paragraphs written on device.",
  ]) {
    self.snapshots = snapshots
  }

  public var isAvailable: Bool { snapshots != nil }

  public func write(_ prompt: String) -> AsyncThrowingStream<String, any Error> {
    AsyncThrowingStream { continuation in
      for snapshot in snapshots ?? [] {
        continuation.yield(snapshot)
      }
      continuation.finish()
    }
  }
}
#endif
