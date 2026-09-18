import DesignComponents
import SwiftUI

struct HoverTilt<Content: View>: View, Animatable {
  var amount: Double
  let isActive: Bool
  @ViewBuilder let content: (CGPoint) -> Content

  nonisolated var animatableData: Double {
    get { amount }
    set { amount = newValue }
  }

  var body: some View {
    TimelineView(.animation(paused: amount == 0)) { context in
      let motion = HoverMotion(time: context.date.timeIntervalSinceReferenceDate, amount: amount)

      content(motion.pose)
        .modifier(CardTilt(isActive: isActive, pose: motion.pose, range: 12))
        .rotationEffect(.degrees(motion.rotation))
        .offset(y: motion.lift)
    }
  }
}
