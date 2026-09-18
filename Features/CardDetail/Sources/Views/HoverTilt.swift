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
      let time = context.date.timeIntervalSinceReferenceDate
      let pose = CGPoint(x: cos(time * 1.6) * 10 * amount, y: sin(time * 2.1) * 7 * amount)

      content(pose)
        .modifier(CardTilt(isActive: isActive, pose: pose, range: 12))
        .rotationEffect(.degrees(sin(time * 1.3) * 2 * amount))
        .offset(y: CGFloat(sin(time * 2.4) * 6 * amount))
    }
  }
}
