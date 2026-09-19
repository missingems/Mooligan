import DesignComponents
import SwiftUI

/// A band of light across whatever it is masked to, which moves as the phone tilts and as a floating
/// badge sways, the way light slides over a glossy sticker or a metal medal.
///
/// Its own view so that the phone's lean, which changes many times a second while the phone moves,
/// redraws only the band: the sticker under it is drawn once.
struct MotionSheen: View {
  var intensity = 0.55

  @State private var size = CGSize(width: 1, height: 1)
  @Environment(\.hoverPose) private var pose
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let isTracking = DeviceTilt.isTracking(isActive: true, scenePhase: scenePhase, reduceMotion: reduceMotion)
    let tilt = isTracking ? DeviceTilt.shared.offset : .zero
    // Where the light falls, as the card's sheen works it out: the phone's lean, and the sway brought
    // down from degrees to the lean's scale. At rest it catches the upper left.
    let x = 0.35 + (tilt.x + pose.x / 40) * 2.5
    let y = 0.3 - (tilt.y + pose.y / 40) * 2.5
    // The band runs at the same slant on anything it lies on: a gradient's unit points stretch with
    // the view, so across a wide badge the slant is set in points and brought back to units.
    let reach = max(size.width, size.height) * 0.6
    let run = CGSize(width: reach / size.width, height: reach * 0.62 / size.height)

    LinearGradient(
      stops: [
        .init(color: .white.opacity(0), location: 0.38),
        .init(color: .white.opacity(intensity), location: 0.5),
        .init(color: .white.opacity(0), location: 0.62),
      ],
      startPoint: UnitPoint(x: x - run.width, y: y - run.height),
      endPoint: UnitPoint(x: x + run.width, y: y + run.height)
    )
    .allowsHitTesting(false)
    .onGeometryChange(for: CGSize.self) { $0.size } action: { newValue in
      if newValue.width > 0, newValue.height > 0 { size = newValue }
    }
    .task(id: isTracking) {
      guard isTracking else { return }
      await DeviceTilt.shared.track()
    }
  }
}
