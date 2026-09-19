@testable import CardDetail
import Foundation

/// An insight writer that writes its first words and then waits for ever, as the model is mid-way
/// through when the reader swipes on. Cancelling the stream is the only way it ends.
struct HangingInsightWriter: CardInsightWriter {
  var isAvailable: Bool { true }

  func write(_ prompt: String) -> AsyncThrowingStream<String, any Error> {
    AsyncThrowingStream { continuation in
      continuation.yield("Half")
      let task = Task {
        try? await Task.sleep(for: .seconds(3600))
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}
