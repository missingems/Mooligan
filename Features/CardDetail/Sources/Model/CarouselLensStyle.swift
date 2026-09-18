import DesignComponents
import SwiftUI

/// How the glass over the strip is ringed, and whether its reflections follow the phone.
struct CarouselLensStyle: Equatable, Sendable {
  let ring: [Color]
  let isTracking: Bool

  init(isLightAppearance: Bool, scenePhase: ScenePhase, reduceMotion: Bool) {
    // A lit edge over a dark body in light mode, the reverse in dark: the ring has to read against
    // the bar behind it, and the stroke is thin enough that a dark stop in the middle alone was lost.
    ring = isLightAppearance == false
      ? [.white.opacity(0.95), .white.opacity(0.25), .white.opacity(0.75)]
      : [.white.opacity(0.95), .black.opacity(0.5), .black.opacity(0.35)]
    isTracking = DeviceTilt.isTracking(isActive: true, scenePhase: scenePhase, reduceMotion: reduceMotion)
  }
}
