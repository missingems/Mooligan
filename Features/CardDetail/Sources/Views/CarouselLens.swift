import DesignComponents
import SwiftUI

struct CarouselLens: View {
  let scrub: CarouselScrub
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let style = CarouselLensStyle(
      isLightAppearance: scrub.isLightAppearance,
      scenePhase: scenePhase,
      reduceMotion: reduceMotion
    )
    let isTracking = style.isTracking
    let tilt = isTracking ? DeviceTilt.shared.offset : .zero

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
            LinearGradient(colors: style.ring, startPoint: .top, endPoint: .bottom),
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
