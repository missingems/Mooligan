import Foundation

/// Thread-safe lock-check-go mechanism to bridge AVFoundation background threads with TCA's state.
final class ScannerGatekeeper: @unchecked Sendable {
  private let lock = NSLock()
  private var _isPaused: Bool = false
  private var _isProcessing: Bool = false
  
  /// Driven by TCA's `isScanningPaused` state
  var isPaused: Bool {
    get { lock.withLock { _isPaused } }
    set { lock.withLock { _isPaused = newValue } }
  }
  
  /// Driven by TCA's `isProcessingFrame` state
  var isProcessing: Bool {
    get { lock.withLock { _isProcessing } }
    set { lock.withLock { _isProcessing = newValue } }
  }
  
  /// Atomic Lock-Check-Go. Returns true if safe to proceed, automatically locking subsequent calls.
  func checkAndLockForProcessing() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    
    if _isPaused || _isProcessing {
      return false
    }
    
    // The Gate is open! Lock it immediately to prevent race conditions.
    _isProcessing = true
    return true
  }
}

private extension NSLock {
  func withLock<T>(_ body: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try body()
  }
}
