@testable import DesignComponents
import CoreGraphics
import Testing

struct CardTiltTests {
  @Test func aPhoneHeldAtRest_shouldLeaveTheCardSquare() {
    let angles = CardTilt.angles(tilt: .zero, pose: .zero, range: 6)

    #expect(angles.pitch == 0)
    #expect(angles.yaw == 0)
  }

  /// The forward lean pitches the card with it; the sideways lean turns it the opposite way.
  @Test func aGentleLean_shouldTurnTheCardThirtyDegreesPerUnitOfGravity() {
    let angles = CardTilt.angles(tilt: CGPoint(x: 0.125, y: 0.0625), pose: .zero, range: 6)

    #expect(angles.pitch == 1.875)
    #expect(angles.yaw == -3.75)
  }

  @Test func aSteepLean_shouldStopAtTheRangeEitherWay() {
    let forwards = CardTilt.angles(tilt: CGPoint(x: -0.5, y: 0.5), pose: .zero, range: 6)
    let backwards = CardTilt.angles(tilt: CGPoint(x: 0.5, y: -0.5), pose: .zero, range: 6)

    #expect(forwards.pitch == 6)
    #expect(forwards.yaw == 6)
    #expect(backwards.pitch == -6)
    #expect(backwards.yaw == -6)
  }

  @Test func thePose_shouldGoOnTopOfTheRange() {
    let angles = CardTilt.angles(tilt: CGPoint(x: -1, y: 1), pose: CGPoint(x: 4, y: 3), range: 12)

    #expect(angles.pitch == 15)
    #expect(angles.yaw == 16)
  }

  @Test func aRangeOfZero_shouldIgnoreThePhoneButNotThePose() {
    let angles = CardTilt.angles(tilt: CGPoint(x: 0.2, y: 0.2), pose: CGPoint(x: 1, y: -2), range: 0)

    #expect(angles.pitch == -2)
    #expect(angles.yaw == 1)
  }
}
