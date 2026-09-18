@testable import DesignComponents
import CoreGraphics
import Testing

/// `CardView` takes its surface's equality as the whole truth about it, so a field left out of the
/// comparison is a field that never reaches the screen once the card is built.
@MainActor struct CardSurfaceTests {
  @Test func surfacesBuiltAlike_shouldBeEqual() {
    let surface = CardSurface(isFoil: true, isActive: false, pose: CGPoint(x: 2, y: -3), intensity: 0.5)

    #expect(surface == CardSurface(isFoil: true, isActive: false, pose: CGPoint(x: 2, y: -3), intensity: 0.5))
  }

  @Test func foilAndSheen_shouldNotBeEqual() {
    #expect(CardSurface(isFoil: true) != CardSurface(isFoil: false))
  }

  @Test func anInactiveSurface_shouldNotEqualAnActiveOne() {
    #expect(CardSurface(isFoil: false, isActive: false) != CardSurface(isFoil: false, isActive: true))
  }

  @Test func aDifferentPose_shouldNotBeEqual() {
    #expect(CardSurface(isFoil: false, pose: CGPoint(x: 4, y: 0)) != CardSurface(isFoil: false, pose: .zero))
    #expect(CardSurface(isFoil: false, pose: CGPoint(x: 0, y: 4)) != CardSurface(isFoil: false, pose: .zero))
  }

  @Test func aDifferentIntensity_shouldNotBeEqual() {
    #expect(CardSurface(isFoil: false, intensity: 0) != CardSurface(isFoil: false, intensity: 1))
  }

  @Test func theDefaults_shouldBeAnActiveUnposedSurfaceAtFullStrength() {
    #expect(CardSurface(isFoil: false) == CardSurface(isFoil: false, isActive: true, pose: .zero, intensity: 1))
  }

  /// The fade after a landing animates the intensity, and nothing else.
  @Test func animatableData_shouldReadAndWriteTheIntensity() {
    var surface = CardSurface(isFoil: true, pose: CGPoint(x: 1, y: 1), intensity: 0.25)
    #expect(surface.animatableData == 0.25)

    surface.animatableData = 0.75

    #expect(surface.animatableData == 0.75)
    #expect(surface == CardSurface(isFoil: true, pose: CGPoint(x: 1, y: 1), intensity: 0.75))
  }

  // MARK: - Light

  @Test func aPhoneAtRestAndAnUnposedCard_shouldLightTheMiddle() {
    #expect(CardSurface.light(tilt: .zero, pose: .zero) == .zero)
  }

  @Test func thePhonesLean_shouldMoveTheLightAsItIs() {
    #expect(CardSurface.light(tilt: CGPoint(x: 0.25, y: -0.125), pose: .zero) == CGPoint(x: 0.25, y: -0.125))
  }

  /// The hover card's pose is in degrees, and 40 of them move the light as far as a whole unit of lean.
  @Test func thePose_shouldMoveTheLightAFortiethAsFar() {
    #expect(CardSurface.light(tilt: .zero, pose: CGPoint(x: 10, y: -20)) == CGPoint(x: 0.25, y: -0.5))
  }

  @Test func theLeanAndThePose_shouldAddUp() {
    #expect(CardSurface.light(tilt: CGPoint(x: 0.5, y: 0.5), pose: CGPoint(x: 20, y: -40)) == CGPoint(x: 1, y: -0.5))
  }

  // MARK: - Foil

  @Test func aCentredLight_shouldLeaveTheFoilAtTheStartOfItsSweep() {
    #expect(CardSurface.foilSweep(light: .zero) == 0)
  }

  /// Both directions of tilt move the one sweep, the sideways one faster, so the bands, the streak
  /// and the crinkle all move together.
  @Test func eitherDirectionOfLight_shouldMoveTheOneSweep() {
    let sideways = CardSurface.foilSweep(light: CGPoint(x: 0.09, y: 0))
    let forwards = CardSurface.foilSweep(light: CGPoint(x: 0, y: 0.09))

    #expect(abs(sideways - 1.6) < 0.000_1)
    #expect(abs(forwards - 1) < 0.000_1)
    #expect(abs(CardSurface.foilSweep(light: CGPoint(x: 0.09, y: 0.09)) - 2.6) < 0.000_1)
  }

  @Test func oppositeLight_shouldSweepTheOtherWay() {
    #expect(CardSurface.foilSweep(light: CGPoint(x: -0.09, y: -0.09)) == -CardSurface.foilSweep(light: CGPoint(x: 0.09, y: 0.09)))
  }
}
