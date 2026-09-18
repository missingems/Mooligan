import DesignComponents
import SwiftUI

struct CarouselLens: View {
  let scrub: CarouselScrub
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let isTracking = scenePhase == .active && reduceMotion == false
    let tilt = isTracking ? DeviceTilt.shared.offset : .zero
    // A lit edge over a dark body in light mode, the reverse in dark: the ring has to read against
    // the bar behind it, and the stroke is thin enough that a dark stop in the middle alone was lost.
    let ring: [Color] = scrub.isLightAppearance == false
      ? [.white.opacity(0.95), .white.opacity(0.25), .white.opacity(0.75)]
      : [.white.opacity(0.95), .black.opacity(0.5), .black.opacity(0.35)]

    Rectangle()
      .fill(.white)
      .frame(width: 64.0, height: 48.0)
      .colorEffect(
        ShaderLibrary.designComponents.carouselGlare(
          .float2(CGSize(width: 64.0, height: 48.0)),
          .float(11.0),
          .float2(tilt)
        )
      )
      .overlay {
        // Stroked outward from the glass, so the ring sits around the card rather than over its edge.
        RoundedRectangle(cornerRadius: 13.5, style: .continuous)
          .strokeBorder(
            LinearGradient(colors: ring, startPoint: .top, endPoint: .bottom),
            lineWidth: 2.5
          )
          .frame(width: 69.0, height: 53.0)
      }
      .task(id: isTracking) {
        guard isTracking else { return }
        await DeviceTilt.shared.track()
      }
      .allowsHitTesting(false)
  }
}
