@testable import CardDetail
import SwiftUI
import Testing

struct CarouselLensStyleTests {
  @Test func whenDark_shouldRingTheGlassInWhite() {
    // The bar is dark, so the whole ring is light against it.
    let style = CarouselLensStyle(isLightAppearance: false, scenePhase: .active, reduceMotion: false)

    #expect(style.ring == [Color.white.opacity(0.95), .white.opacity(0.25), .white.opacity(0.75)])
  }

  @Test func whenLight_shouldRingTheGlassWithALitEdgeOverADarkBody() {
    let style = CarouselLensStyle(isLightAppearance: true, scenePhase: .active, reduceMotion: false)

    #expect(style.ring == [Color.white.opacity(0.95), .black.opacity(0.5), .black.opacity(0.35)])
  }

  @Test func whenActive_shouldFollowThePhone() {
    #expect(CarouselLensStyle(isLightAppearance: false, scenePhase: .active, reduceMotion: false).isTracking)
  }

  @Test(arguments: [ScenePhase.inactive, .background])
  func whenNotActive_shouldStopFollowingThePhone(scenePhase: ScenePhase) {
    // Motion updates stop with the app, rather than running on behind the lock screen.
    #expect(CarouselLensStyle(isLightAppearance: false, scenePhase: scenePhase, reduceMotion: false).isTracking == false)
  }

  @Test func whenMotionIsReduced_shouldHoldTheReflectionsStill() {
    #expect(CarouselLensStyle(isLightAppearance: false, scenePhase: .active, reduceMotion: true).isTracking == false)
  }
}
