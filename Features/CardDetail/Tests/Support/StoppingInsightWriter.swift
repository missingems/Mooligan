@testable import CardDetail
import Foundation

/// An insight writer that writes the snapshots a test gives it and then fails, the way the model
/// does when its guardrails stop it part-way.
struct StoppingInsightWriter: CardInsightWriter {
  let snapshots: [String]

  var isAvailable: Bool { true }

  func write(_ prompt: String) -> AsyncThrowingStream<String, any Error> {
    AsyncThrowingStream { continuation in
      for snapshot in snapshots {
        continuation.yield(snapshot)
      }
      continuation.finish(throwing: CancellationError())
    }
  }
}
