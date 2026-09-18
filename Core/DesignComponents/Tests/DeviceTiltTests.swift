@testable import DesignComponents
import CoreGraphics
import CoreMotion
import SwiftUI
import Testing

/// Each test makes its own `DeviceTilt` rather than using `shared`, which other tests' views could
/// be holding.
@MainActor struct DeviceTiltTests {
  /// Lets the tracking tasks run up to their sleep, which is where they hold their lease.
  private func settle(until condition: () -> Bool) async {
    var attempts = 0
    while condition() == false, attempts < 1_000 {
      await Task.yield()
      attempts += 1
    }
  }

  @Test(.enabled(if: CMMotionManager().isDeviceMotionAvailable == false, "Only where there is no motion to read, as on the simulator"))
  func withoutMotion_everyLeaseShouldBeHandedBackAndTheCardShouldStayAtRest() async {
    let tilt = DeviceTilt()
    let first = Task { await tilt.track() }
    let second = Task { await tilt.track() }
    await settle { tilt.state.viewers == 2 }

    #expect(tilt.state.viewers == 2)
    #expect(tilt.offset == .zero)

    first.cancel()
    await first.value
    #expect(tilt.state.viewers == 1)
    #expect(tilt.offset == .zero)

    second.cancel()
    await second.value
    #expect(tilt.state.viewers == 0)
    #expect(tilt.offset == .zero)
  }

  /// A view can disappear before its task first runs, and the lease must still come back.
  @Test func aTrackCancelledBeforeItStarts_shouldStillHandItsLeaseBack() async {
    let tilt = DeviceTilt()
    let tracking = Task { await tilt.track() }
    tracking.cancel()
    await tracking.value

    #expect(tilt.state.viewers == 0)
    #expect(tilt.offset == .zero)
  }

  // MARK: - Whether a view follows the phone

  @Test func anActiveViewInTheFrontmostApp_shouldFollowThePhone() {
    #expect(DeviceTilt.isTracking(isActive: true, scenePhase: .active, reduceMotion: false))
  }

  @Test func aViewThatHasNotAskedTo_shouldNotFollowThePhone() {
    // The scrub's cards hold still until they are on show.
    #expect(DeviceTilt.isTracking(isActive: false, scenePhase: .active, reduceMotion: false) == false)
  }

  @Test(arguments: [ScenePhase.inactive, .background])
  func anAppNotInFront_shouldStopFollowingThePhone(scenePhase: ScenePhase) {
    // Motion updates stop with the app, rather than running on behind the lock screen.
    #expect(DeviceTilt.isTracking(isActive: true, scenePhase: scenePhase, reduceMotion: false) == false)
  }

  @Test func reduceMotion_shouldHoldEveryCardStill() {
    #expect(DeviceTilt.isTracking(isActive: true, scenePhase: .active, reduceMotion: true) == false)
  }
}
