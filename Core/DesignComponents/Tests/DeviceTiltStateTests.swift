@testable import DesignComponents
import CoreGraphics
import Testing
import UIKit

struct DeviceTiltStateTests {
  private func watched() -> DeviceTiltState {
    var state = DeviceTiltState()
    _ = state.addViewer()
    return state
  }

  private func isClose(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
    abs(lhs.x - rhs.x) < 0.000_001 && abs(lhs.y - rhs.y) < 0.000_001
  }

  // MARK: - Orientation

  @Test func inPortrait_gravityShouldBeTheDevicesOwn() {
    #expect(DeviceTiltState.gravity(x: 0.3, y: -0.8, in: .portrait) == CGPoint(x: 0.3, y: -0.8))
  }

  @Test func withNoOrientationToGoBy_gravityShouldBeTakenAsPortrait() {
    #expect(DeviceTiltState.gravity(x: 0.3, y: -0.8, in: nil) == CGPoint(x: 0.3, y: -0.8))
    #expect(DeviceTiltState.gravity(x: 0.3, y: -0.8, in: .unknown) == CGPoint(x: 0.3, y: -0.8))
  }

  @Test func upsideDown_bothAxesShouldTurnRound() {
    #expect(DeviceTiltState.gravity(x: 0.3, y: -0.8, in: .portraitUpsideDown) == CGPoint(x: -0.3, y: 0.8))
  }

  @Test func inLandscapeRight_theDevicesAxesShouldTurnAQuarterOneWay() {
    #expect(DeviceTiltState.gravity(x: 0.3, y: -0.8, in: .landscapeRight) == CGPoint(x: 0.8, y: 0.3))
  }

  @Test func inLandscapeLeft_theDevicesAxesShouldTurnAQuarterTheOtherWay() {
    #expect(DeviceTiltState.gravity(x: 0.3, y: -0.8, in: .landscapeLeft) == CGPoint(x: -0.8, y: -0.3))
  }

  // MARK: - Viewers

  @Test func onlyTheFirstViewer_shouldStartMotionUpdates() {
    var state = DeviceTiltState()
    let first = state.addViewer()
    let second = state.addViewer()

    #expect(first)
    #expect(second == false)
    #expect(state.viewers == 2)
  }

  @Test func onlyTheLastViewer_shouldStopMotionUpdates() {
    var state = DeviceTiltState()
    _ = state.addViewer()
    _ = state.addViewer()
    let first = state.removeViewer()
    let last = state.removeViewer()

    #expect(first == false)
    #expect(last)
    #expect(state.viewers == 0)
  }

  @Test func whenTheLastViewerLeaves_theCardShouldGoBackToRest() {
    var state = watched()
    _ = state.receive(CGPoint(x: 0, y: -1))
    _ = state.receive(CGPoint(x: 0.2, y: -1))
    #expect(state.offset != .zero)

    _ = state.removeViewer()

    #expect(state.offset == .zero)
  }

  @Test func withNobodyWatching_samplesShouldBeIgnored() {
    var state = DeviceTiltState()
    _ = state.receive(CGPoint(x: 0, y: -1))
    let moved = state.receive(CGPoint(x: 0.5, y: -0.5))

    #expect(moved == false)
    #expect(state.offset == .zero)
  }

  // MARK: - Smoothing

  @Test func theFirstSample_shouldBeTakenAsTheNeutralPose() {
    var state = watched()
    let moved = state.receive(CGPoint(x: 0.4, y: -0.6))

    #expect(moved == false)
    #expect(state.offset == .zero)
  }

  @Test func aChangeOfAngle_shouldLeanTheCardAQuarterOfTheWayEachSample() {
    var state = watched()
    _ = state.receive(CGPoint(x: 0, y: -1))

    let moved = state.receive(CGPoint(x: 0.2, y: -0.8))

    #expect(moved)
    #expect(isClose(state.offset, CGPoint(x: 0.05, y: 0.05)))
  }

  @Test func holdingTheNewAngle_theCardShouldSettleBackFlat() {
    var state = watched()
    _ = state.receive(CGPoint(x: 0, y: -1))

    var steepest: CGFloat = 0
    for _ in 0..<1_000 {
      _ = state.receive(CGPoint(x: 0.2, y: -1))
      steepest = max(steepest, state.offset.x)
    }

    #expect(steepest > 0.15)
    #expect(abs(state.offset.x) < 0.005)
    #expect(state.offset.y == 0)
  }

  @Test func aTremorTooSmallToSee_shouldBeHeldBackUntilItBuildsUp() {
    var state = watched()
    _ = state.receive(CGPoint(x: 0, y: -1))

    let first = state.receive(CGPoint(x: 0.01, y: -1))
    #expect(first == false)
    #expect(state.offset == .zero)

    let second = state.receive(CGPoint(x: 0.01, y: -1))
    #expect(second)
    #expect(isClose(state.offset, CGPoint(x: 0.00435, y: 0)))
  }

  @Test func aSecondViewer_shouldNotResetTheLean() {
    var state = watched()
    _ = state.receive(CGPoint(x: 0, y: -1))
    _ = state.receive(CGPoint(x: 0.2, y: -1))

    _ = state.addViewer()
    _ = state.receive(CGPoint(x: 0.2, y: -1))

    #expect(isClose(state.offset, CGPoint(x: 0.087, y: 0)))
  }

  @Test func aViewerArrivingAfterEveryoneLeft_shouldStartFromWhereverThePhoneIsThen() {
    var state = watched()
    _ = state.receive(CGPoint(x: 0, y: -1))
    _ = state.receive(CGPoint(x: 0.2, y: -1))
    _ = state.removeViewer()
    _ = state.addViewer()

    let settled = state.receive(CGPoint(x: 0.6, y: -0.4))
    #expect(settled == false)
    #expect(state.offset == .zero)

    let leaned = state.receive(CGPoint(x: 0.8, y: -0.4))
    #expect(leaned)
    #expect(isClose(state.offset, CGPoint(x: 0.05, y: 0)))
  }
}
