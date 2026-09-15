import SwiftUI

struct ScrubPressRule: Equatable, Sendable {
  static let standard = ScrubPressRule(minimumPressDuration: 0.3, allowableMovement: 10.0)

  let minimumPressDuration: TimeInterval
  let allowableMovement: CGFloat

  func hasDrifted(from origin: CGPoint, to point: CGPoint) -> Bool {
    hypot(point.x - origin.x, point.y - origin.y) > allowableMovement
  }
}
