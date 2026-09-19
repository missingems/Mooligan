import Foundation

/// Writes a short explanation of one card detail.
public protocol CardInsightWriter: Sendable {
  /// Whether this device can write at all: Apple Intelligence is supported, switched on and ready.
  var isAvailable: Bool { get }

  /// The explanation as it is written, each element the whole text so far.
  func write(_ prompt: String) -> AsyncThrowingStream<String, any Error>
}
