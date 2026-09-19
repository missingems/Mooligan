import SwiftUI

/// A card floating in place: an idle sway and bob, with the phone's tilt on top, easing in and out
/// with `amount`. `content` gets the pose, to light a `CardSurface` from.
public struct HoverTilt<Content: View>: View, Animatable {
  var amount: Double
  let isActive: Bool
  @ViewBuilder let content: (CGPoint) -> Content

  public init(amount: Double, isActive: Bool, @ViewBuilder content: @escaping (CGPoint) -> Content) {
    self.amount = amount
    self.isActive = isActive
    self.content = content
  }

  public nonisolated var animatableData: Double {
    get { amount }
    set { amount = newValue }
  }

  public var body: some View {
    TimelineView(.animation(paused: amount == 0)) { context in
      let motion = HoverMotion(time: context.date.timeIntervalSinceReferenceDate, amount: amount)

      content(motion.pose)
        .modifier(CardTilt(isActive: isActive, pose: motion.pose, range: 12))
        .rotationEffect(.degrees(motion.rotation))
        .offset(y: motion.lift)
    }
  }
}
