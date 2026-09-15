import Foundation

/// Lets one snapshot own a window at a time.
///
/// Swift Testing runs suites in parallel, and each snapshot shows its own key window and draws the
/// key window's hierarchy. Two at once make each other's window key, so one captures the other's
/// content. Hold this from showing the window until it is hidden again.
@MainActor
enum SnapshotWindow {
  private static var isBusy = false
  private static var waiters: [CheckedContinuation<Void, Never>] = []

  static func acquire() async {
    while isBusy {
      await withCheckedContinuation { waiters.append($0) }
    }
    isBusy = true
  }

  static func release() {
    isBusy = false
    if waiters.isEmpty == false {
      waiters.removeFirst().resume()
    }
  }
}
