import SwiftUI

/// A badge turned about its vertical axis by `angle`, showing `back` while it faces away, as a badge
/// spun on its edge shows its reverse rather than its face seen through from behind.
///
/// Animatable, so which side is up is decided on every frame of the spin, not only at its ends.
struct BadgeSpin<Front: View, Back: View>: View, Animatable {
  var angle: Double
  let front: Front
  let back: Back

  nonisolated var animatableData: Double {
    get { angle }
    set { angle = newValue }
  }

  var body: some View {
    let turned = abs(angle.truncatingRemainder(dividingBy: 360))
    let isFacingAway = turned > 90 && turned < 270

    ZStack {
      front.opacity(isFacingAway ? 0 : 1)
      // Drawn the right way round and mirrored by the turn itself, as a real badge's back is.
      back.opacity(isFacingAway ? 1 : 0)
    }
    // The sides swap the instant the badge is edge on, not crossfaded over the spin's animation.
    .transaction { $0.animation = nil }
    .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
  }
}
