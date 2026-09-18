import CoreGraphics
import UIKit

/// `DeviceTilt`'s arithmetic, apart from CoreMotion so it can be fed samples by hand.
struct DeviceTiltState {
  private(set) var viewers = 0
  private(set) var offset: CGPoint = .zero
  private var smoothed: CGPoint = .zero
  private var neutral: CGPoint?

  /// Whether this is the first viewer, which starts motion updates. The lean is measured afresh from
  /// however the phone is held when it arrives.
  mutating func addViewer() -> Bool {
    viewers += 1
    guard viewers == 1 else { return false }
    neutral = nil
    smoothed = .zero
    return true
  }

  /// Whether that was the last viewer, which stops motion updates and leaves the card at rest.
  mutating func removeViewer() -> Bool {
    viewers -= 1
    guard viewers == 0 else { return false }
    offset = .zero
    return true
  }

  /// Gravity in the interface's axes rather than the device's, so a card leans the same way to the
  /// eye whichever way up the phone is held.
  static func gravity(x: Double, y: Double, in orientation: UIInterfaceOrientation?) -> CGPoint {
    switch orientation {
    case .landscapeRight: CGPoint(x: -y, y: x)
    case .landscapeLeft: CGPoint(x: y, y: -x)
    case .portraitUpsideDown: CGPoint(x: -x, y: -y)
    default: CGPoint(x: x, y: y)
    }
  }

  /// Whether `offset` moved.
  mutating func receive(_ gravity: CGPoint) -> Bool {
    guard viewers > 0 else { return false }
    // The neutral pose creeps after the phone, so a card held at one angle for a few seconds settles
    // flat again and only a change of angle leans it.
    let rest = neutral ?? gravity
    neutral = CGPoint(x: rest.x + (gravity.x - rest.x) * 0.01, y: rest.y + (gravity.y - rest.y) * 0.01)
    smoothed = CGPoint(
      x: smoothed.x + (gravity.x - rest.x - smoothed.x) * 0.25,
      y: smoothed.y + (gravity.y - rest.y - smoothed.y) * 0.25
    )

    // Held back until the lean has moved by more than can be seen, so a phone at rest does not
    // redraw every tilting view on every sample.
    guard abs(smoothed.x - offset.x) > 0.004 || abs(smoothed.y - offset.y) > 0.004 else { return false }
    offset = smoothed
    return true
  }
}
