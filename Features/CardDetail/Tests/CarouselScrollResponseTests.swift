@testable import CardDetail
import SwiftUI
import Testing

struct CarouselScrollResponseTests {
  private func response(
    to phase: ScrollPhase,
    isHovering: Bool = true,
    isLanding: Bool = false,
    velocity: CGFloat = 0,
    releaseVelocity: CGFloat = 0,
    isCentredOnSelection: Bool = true
  ) -> CarouselScrollResponse? {
    CarouselScrollResponse(
      phase: phase,
      isHovering: isHovering,
      isLanding: isLanding,
      velocity: velocity,
      releaseVelocity: releaseVelocity,
      isCentredOnSelection: isCentredOnSelection
    )
  }

  // MARK: - Starting a scrub

  @Test(arguments: [false, true], [false, true])
  func whenAFingerTakesTheStrip_shouldBeginAScrub(isHovering: Bool, isLanding: Bool) {
    // Even mid-landing: a new scrub ends the last one.
    #expect(response(to: .interacting, isHovering: isHovering, isLanding: isLanding) == .beginScrub)
  }

  // MARK: - Letting go

  @Test func whenLettingGoOfAStillStrip_shouldLandAtOnce() {
    #expect(response(to: .decelerating, velocity: 0, releaseVelocity: 0) == .land)
    #expect(response(to: .decelerating, velocity: 119, releaseVelocity: -119) == .land)
  }

  @Test func whenTheFingerWasMovingAtTheThreshold_shouldCoastInstead() {
    #expect(response(to: .decelerating, velocity: 120) == nil)
    #expect(response(to: .decelerating, velocity: -120) == nil)
  }

  @Test func whenTheLiftWasAFlick_shouldCoastEvenIfTheFingerReadsStill() {
    // The tracker zeroes the finger's speed on the lift, so a fast release shows only in the
    // release speed.
    #expect(response(to: .decelerating, velocity: 0, releaseVelocity: 1_400) == nil)
    #expect(response(to: .decelerating, velocity: 0, releaseVelocity: -600) == nil)
  }

  @Test func whenTheStripComesToRestAfterACoast_shouldLandOnceSettled() {
    #expect(response(to: .idle, velocity: 0, releaseVelocity: 1_400) == .landOnceSettled)
    #expect(response(to: .idle, isCentredOnSelection: false) == .landOnceSettled)
  }

  @Test func whenNotHovering_shouldNotLand() {
    #expect(response(to: .decelerating, isHovering: false) == nil)
    #expect(response(to: .idle, isHovering: false, isCentredOnSelection: true) == nil)
  }

  // MARK: - Coming back to the selection

  @Test func whenTheStripRestsOffTheSelectedCard_shouldRecentre() {
    #expect(response(to: .idle, isHovering: false, isLanding: false, isCentredOnSelection: false) == .recentre)
  }

  @Test func whenACardIsLanding_shouldLeaveTheStripWhereItIs() {
    #expect(response(to: .idle, isHovering: false, isLanding: true, isCentredOnSelection: false) == nil)
  }

  @Test func whenStillMoving_shouldNotRecentre() {
    #expect(response(to: .decelerating, isHovering: false, isCentredOnSelection: false) == nil)
    #expect(response(to: .animating, isHovering: false, isCentredOnSelection: false) == nil)
  }

  // MARK: - Everything else

  @Test(arguments: [false, true], [false, true])
  func whenTrackingOrAnimating_shouldDoNothing(isHovering: Bool, isCentredOnSelection: Bool) {
    #expect(response(to: .tracking, isHovering: isHovering, isCentredOnSelection: isCentredOnSelection) == nil)
    #expect(response(to: .animating, isHovering: isHovering, isCentredOnSelection: isCentredOnSelection) == nil)
  }
}
