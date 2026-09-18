@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import Observation
import Testing

@MainActor struct CarouselScrubTests {
  private let cardId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
  private let otherCardId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
  private let front = DisplayableCardImage.single(displayingImageURL: URL(string: "https://example.com/front.jpg")!, id: "front")
  private let back = DisplayableCardImage.single(displayingImageURL: URL(string: "https://example.com/back.jpg")!, id: "back")

  // MARK: - Settling

  @Test func whenNothingIsHappening_shouldBeSettled() {
    #expect(CarouselScrub().isSettledUntracked)
  }

  @Test func whenHoveringOrLanding_shouldNotBeSettled() {
    let hovering = CarouselScrub()
    hovering.isHovering = true
    let landing = CarouselScrub()
    landing.isLanding = true

    #expect(hovering.isSettledUntracked == false)
    #expect(landing.isSettledUntracked == false)
  }

  @Test func whenReadingIsSettledUntracked_shouldNotObserveTheScrub() {
    // A page reads this in its initialiser, inside the pager's body. A tracked read there would
    // re-render the pager on every hover.
    let scrub = CarouselScrub()
    let didChange = LockIsolated(false)

    withObservationTracking {
      _ = scrub.isSettledUntracked
    } onChange: {
      didChange.setValue(true)
    }
    scrub.isHovering = true
    scrub.isLanding = true

    #expect(didChange.value == false)
  }

  @Test(.timeLimit(.minutes(1)))
  func whenAlreadySettled_waitUntilSettledShouldReturnWithoutWaitingForAChange() async {
    let scrub = CarouselScrub()

    // Nothing on the scrub changes from here on, so a wait that looked for a change would still be
    // waiting when the deadline passes.
    let returnedBeforeTheDeadline = await withTaskGroup(of: Bool.self) { group in
      group.addTask {
        await scrub.waitUntilSettled()
        return true
      }
      group.addTask {
        try? await Task.sleep(for: .seconds(5))
        return false
      }
      let first = await group.next() ?? false
      group.cancelAll()
      return first
    }

    #expect(returnedBeforeTheDeadline)
  }

  /// Gives a waiter on the main actor time to see the change just made, so a wait that wrongly ended
  /// on it would have ended by the time this returns.
  private func letTheWaiterSeeTheChange() async throws {
    try await Task.sleep(for: .milliseconds(50))
  }

  @Test(.timeLimit(.minutes(1)))
  func whenHoveringAndLanding_waitUntilSettledShouldResumeOnlyOnceBothHaveEnded() async throws {
    let scrub = CarouselScrub()
    scrub.isHovering = true
    scrub.isLanding = true
    let didSettle = LockIsolated(false)
    let waiter = Task {
      await scrub.waitUntilSettled()
      didSettle.setValue(true)
    }

    // The hover ends as the card starts to fly, but the landing is still under way.
    scrub.isHovering = false
    try await letTheWaiterSeeTheChange()
    #expect(didSettle.value == false)

    // A new scrub starts and lets go again while the same landing is still under way.
    scrub.isHovering = true
    try await letTheWaiterSeeTheChange()
    scrub.isHovering = false
    try await letTheWaiterSeeTheChange()
    #expect(didSettle.value == false)

    // When the landing ends.
    scrub.endLanding()
    await waiter.value

    #expect(didSettle.value)
  }

  @Test(.timeLimit(.minutes(1)))
  func whenTheLandingEndsWhileStillHovering_waitUntilSettledShouldResumeOnlyOnceTheHoverEnds() async throws {
    let scrub = CarouselScrub()
    scrub.isHovering = true
    scrub.isLanding = true
    let didSettle = LockIsolated(false)
    let waiter = Task {
      await scrub.waitUntilSettled()
      didSettle.setValue(true)
    }

    // The last landing ends under a finger that is still scrubbing.
    scrub.endLanding()
    try await letTheWaiterSeeTheChange()
    #expect(didSettle.value == false)

    // When the finger lets go.
    scrub.isHovering = false
    await waiter.value

    #expect(didSettle.value)
  }

  // MARK: - Ending a landing

  @Test func whenEndingALanding_shouldClearEverythingTheLandingSetUp() {
    let scrub = CarouselScrub()
    scrub.isLanding = true
    scrub.isFlying = true
    scrub.isPageHidden = true
    scrub.outgoing = front
    scrub.landingBackdrop = URL(string: "https://example.com/backdrop.jpg")
    scrub.pageReadyId = cardId
    let landing = Task<Void, Never> {
      try? await Task.sleep(for: .seconds(3_600))
    }
    scrub.landing = landing

    scrub.endLanding()

    #expect(scrub.isLanding == false)
    #expect(scrub.isFlying == false)
    #expect(scrub.isPageHidden == false)
    #expect(scrub.outgoing == nil)
    #expect(scrub.landingBackdrop == nil)
    #expect(scrub.pageReadyId == nil)
    #expect(scrub.landing == nil)
    #expect(landing.isCancelled)
  }

  @Test func whenEndingALanding_shouldLeaveTheHoverAlone() {
    // A new scrub ends the last landing and goes on hovering, so the hover is the caller's to end.
    let scrub = CarouselScrub()
    scrub.isHovering = true
    scrub.isLanding = true
    scrub.cardId = cardId
    scrub.selectedId = otherCardId
    scrub.image = front

    scrub.endLanding()

    #expect(scrub.isHovering)
    #expect(scrub.cardId == cardId)
    #expect(scrub.selectedId == otherCardId)
    #expect(scrub.image == front)
  }

  @Test func whenNothingIsLanding_endLandingShouldBeHarmless() {
    let scrub = CarouselScrub()

    scrub.endLanding()

    #expect(scrub.isSettledUntracked)
    #expect(scrub.landing == nil)
  }

  // MARK: - The card under the glass

  @Test func whenNothingIsShown_shouldNotBeShowingAnyCard() {
    #expect(CarouselScrub().isShowing(cardId, image: front) == false)
  }

  @Test func whenTheSameCardAndFaceAreShown_shouldBeShowingIt() {
    let scrub = CarouselScrub()
    scrub.cardId = cardId
    scrub.image = front

    #expect(scrub.isShowing(cardId, image: front))
  }

  @Test func whenTheShownCardHasTurnedOver_shouldNotBeShowingItsNewFace() {
    let scrub = CarouselScrub()
    scrub.cardId = cardId
    scrub.image = front

    #expect(scrub.isShowing(cardId, image: back) == false)
  }

  @Test func whenAnotherCardIsShown_shouldNotBeShowingThisOne() {
    let scrub = CarouselScrub()
    scrub.cardId = otherCardId
    scrub.image = front

    #expect(scrub.isShowing(cardId, image: front) == false)
  }

  // MARK: - The finger on the strip

  @Test func whenAFingerGoesDown_shouldTrackItAndForgetTheLastRelease() {
    let scrub = CarouselScrub()
    scrub.releaseVelocity = 900

    scrub.fingerDown(at: CGPoint(x: 120, y: 780), velocity: 40)

    #expect(scrub.location == CGPoint(x: 120, y: 780))
    #expect(scrub.velocity == 40)
    #expect(scrub.releaseVelocity == 0)
  }

  @Test func whenTheFingerMoves_shouldFollowItWithoutTouchingTheRelease() {
    let scrub = CarouselScrub()
    scrub.releaseVelocity = 300

    scrub.fingerMoved(to: CGPoint(x: 160, y: 782), velocity: -250)

    #expect(scrub.location == CGPoint(x: 160, y: 782))
    #expect(scrub.velocity == -250)
    #expect(scrub.releaseVelocity == 300)
  }

  @Test func whenTheFingerReportsNoSpeed_shouldTreatItAsStill() {
    let scrub = CarouselScrub()
    scrub.velocity = 500

    scrub.fingerMoved(to: CGPoint(x: 160, y: 782), velocity: nil)

    #expect(scrub.velocity == 0)
  }

  @Test func whenTheFingerLifts_shouldKeepTheLiftsSpeedAsTheRelease() {
    let scrub = CarouselScrub()
    scrub.velocity = 60

    scrub.fingerLifted(velocity: 1_400)

    #expect(scrub.releaseVelocity == 1_400)
    #expect(scrub.velocity == 0)
  }

  @Test func whenTheLiftReportsNoSpeed_shouldKeepTheLastTrackedSpeedAsTheRelease() {
    let scrub = CarouselScrub()
    scrub.velocity = -80

    scrub.fingerLifted(velocity: nil)

    #expect(scrub.releaseVelocity == -80)
    #expect(scrub.velocity == 0)
  }
}
