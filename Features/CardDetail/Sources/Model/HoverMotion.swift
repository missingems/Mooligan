import Foundation

/// The hovering card's idle sway and bob at a moment, scaled by how far into the hover it is, so it
/// settles flat as the card leaves the hover.
struct HoverMotion: Equatable, Sendable {
  let pose: CGPoint
  let rotation: Double
  let lift: CGFloat

  init(time: TimeInterval, amount: Double) {
    pose = CGPoint(x: cos(time * 1.6) * 10 * amount, y: sin(time * 2.1) * 7 * amount)
    rotation = sin(time * 1.3) * 2 * amount
    lift = CGFloat(sin(time * 2.4) * 6 * amount)
  }
}
