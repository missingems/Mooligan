@testable import CardDetail
import ComposableArchitecture
import Foundation
import Networking
import ScryfallKit
import Testing

/// The state a scrub hands the page over with: the card put on the hover card, and what a landing
/// sets up before the flight starts.
@MainActor struct CarouselScrubLandingTests {
  private let cardId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
  private let otherCardId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

  private func url(_ id: UUID, _ face: String) -> URL {
    URL(string: "https://cards.scryfall.io/normal/\(face)/\(id.uuidString).jpg")!
  }

  private func imageUris(_ id: UUID, _ face: String) -> Card.ImageUris {
    Card.ImageUris(
      small: nil,
      normal: url(id, face).absoluteString,
      large: nil,
      png: nil,
      artCrop: nil,
      borderCrop: nil
    )
  }

  /// A page as the pager holds it. A transform card has an image for each face, and a split card
  /// lies on its side.
  private func page(
    _ id: UUID,
    layout: Card.Layout = .normal,
    finishes: [Card.Finish] = [.nonfoil],
    isTurnedOver: Bool = false
  ) -> CardDetailFeature.State {
    var card = Card.mock(id: id)
    card.layout = layout
    card.finishes = finishes
    card.imageUris = imageUris(id, "front")
    if layout == .transform {
      card.imageUris = nil
      card.cardFaces = [
        Card.Face(imageUris: imageUris(id, "front"), manaCost: "", name: "Front"),
        Card.Face(imageUris: imageUris(id, "back"), manaCost: "", name: "Back"),
      ]
    }

    var state = CardDetailFeature.State(
      card: card,
      queryType: .search(SearchQuery(page: 1, sortMode: .name, sortDirection: .auto))
    )
    if isTurnedOver {
      state.displayableCardImage = state.displayableCardImage?.toggled()
    }
    return state
  }

  // MARK: - The hover card

  @Test func whenShowingACard_shouldPutItOnTheHoverCard() {
    let scrub = CarouselScrub()
    let card = page(cardId, layout: .split, finishes: [.foil])

    scrub.show(card)

    #expect(scrub.cardId == cardId)
    #expect(scrub.image == card.displayableCardImage)
    #expect(scrub.isLandscape)
    #expect(scrub.isFoil)
  }

  @Test func whenShowingAnUprightCardWithoutFoil_shouldClearTheLastCardsLook() {
    let scrub = CarouselScrub()
    scrub.show(page(otherCardId, layout: .split, finishes: [.foil]))

    scrub.show(page(cardId))

    #expect(scrub.cardId == cardId)
    #expect(scrub.isLandscape == false)
    #expect(scrub.isFoil == false)
  }

  @Test func whenACardIsPrintedBothWays_shouldNotShowItAsFoil() {
    // Only a card that exists solely as a foil is drawn as one.
    let scrub = CarouselScrub()

    scrub.show(page(cardId, finishes: [.nonfoil, .foil]))

    #expect(scrub.isFoil == false)
  }

  @Test func whenShowingTheCardAlreadyShown_shouldWriteNothing() {
    // The strip asks on every step of a scrub, and each write would redraw the hover card.
    let scrub = CarouselScrub()
    let card = page(cardId)
    scrub.show(card)
    scrub.isFoil = true

    scrub.show(card)

    #expect(scrub.isFoil)
  }

  @Test func whenTheShownCardHasTurnedOver_shouldShowItAgain() {
    let scrub = CarouselScrub()
    scrub.show(page(cardId, layout: .transform))
    let turned = page(cardId, layout: .transform, isTurnedOver: true)

    scrub.show(turned)

    #expect(scrub.image == turned.displayableCardImage)
    #expect(scrub.image?.faceDirection == .back)
  }

  // MARK: - The card the pager is leaving

  @Test func whenLanding_shouldDrawTheOutgoingCardWhereThePageHadIt() {
    let scrub = CarouselScrub()
    let frame = CGRect(x: 67, y: 81, width: 268, height: 374)
    scrub.cardFrame = frame
    let outgoing = page(otherCardId)

    scrub.beginLanding(from: outgoing)

    #expect(scrub.outgoing == outgoing.displayableCardImage)
    #expect(scrub.outgoingFrame == frame)
    #expect(scrub.outgoingIsLandscape == false)
    #expect(scrub.outgoingIsFoil == false)
  }

  @Test func whenTheOutgoingCardIsSidewaysAndFoil_shouldDrawItSo() {
    let scrub = CarouselScrub()

    scrub.beginLanding(from: page(otherCardId, layout: .split, finishes: [.foil]))

    #expect(scrub.outgoingIsLandscape)
    #expect(scrub.outgoingIsFoil)
  }

  @Test func whenLanding_shouldKeepTheOutgoingPagesBackdropBehindThePager() {
    let scrub = CarouselScrub()

    scrub.beginLanding(from: page(otherCardId))

    #expect(scrub.landingBackdrop == url(otherCardId, "front"))
  }

  @Test func whenTheOutgoingCardIsTurnedOver_shouldKeepItsBackBehindThePager() {
    // The backdrop is the one its page was showing, so nothing changes behind the flight.
    let scrub = CarouselScrub()
    let outgoing = page(otherCardId, layout: .transform, isTurnedOver: true)

    scrub.beginLanding(from: outgoing)

    #expect(scrub.landingBackdrop == url(otherCardId, "back"))
    #expect(scrub.outgoing?.faceDirection == .back)
  }

  @Test func whenTheOutgoingCardShowsItsFront_shouldKeepItsFrontBehindThePager() {
    let scrub = CarouselScrub()

    scrub.beginLanding(from: page(otherCardId, layout: .transform))

    #expect(scrub.landingBackdrop == url(otherCardId, "front"))
  }

  @Test func whenThereIsNoOutgoingCard_shouldDrawNoneAndKeepNoBackdrop() {
    // Left over from an earlier landing.
    let scrub = CarouselScrub()
    scrub.beginLanding(from: page(otherCardId, layout: .split, finishes: [.foil]))

    scrub.beginLanding(from: nil)

    #expect(scrub.outgoing == nil)
    #expect(scrub.landingBackdrop == nil)
    #expect(scrub.outgoingIsLandscape == false)
    #expect(scrub.outgoingIsFoil == false)
  }

  // MARK: - The landing page

  @Test func whenLanding_shouldHideThePageUntilItReportsReady() {
    let scrub = CarouselScrub()
    scrub.isOutgoingHidden = true
    scrub.pageReadyId = cardId

    scrub.beginLanding(from: page(otherCardId))

    #expect(scrub.isLanding)
    #expect(scrub.isPageHidden)
    #expect(scrub.pageReadyId == nil)
    #expect(scrub.isOutgoingHidden == false)
    #expect(scrub.isFlying == false)
  }

  @Test func whenLanding_shouldLeaveTheHoverCardToTheFlight() {
    // The hover ends as the flight starts, which waits for the page.
    let scrub = CarouselScrub()
    let card = page(cardId)
    scrub.show(card)
    scrub.isHovering = true

    scrub.beginLanding(from: page(otherCardId))

    #expect(scrub.isHovering)
    #expect(scrub.cardId == cardId)
    #expect(scrub.image == card.displayableCardImage)
  }

  // MARK: - Waiting for the page

  /// A wait on its own task, and whether it has returned.
  private func startWaiting(
    for id: UUID,
    on scrub: CarouselScrub,
    clock: TestClock<Duration>
  ) -> (task: Task<Void, Never>, didReturn: LockIsolated<Bool>) {
    let didReturn = LockIsolated(false)
    let task = Task {
      await scrub.waitForPage(id, clock: clock)
      didReturn.setValue(true)
    }
    return (task, didReturn)
  }

  @Test(.timeLimit(.minutes(1)))
  func whenThePageIsAlreadyReady_shouldNotWait() async {
    let scrub = CarouselScrub()
    scrub.pageReadyId = cardId

    // The clock never moves, so any sleep would hang here.
    await scrub.waitForPage(cardId, clock: TestClock())
  }

  @Test func whenThePageReportsReadyPartWay_shouldStopWaitingAtTheNextPoll() async {
    let scrub = CarouselScrub()
    let clock = TestClock()
    let wait = startWaiting(for: cardId, on: scrub, clock: clock)

    await clock.advance(by: .milliseconds(16))
    #expect(wait.didReturn.value == false)

    scrub.pageReadyId = cardId
    await clock.advance(by: .milliseconds(8))
    await Task.megaYield()

    #expect(wait.didReturn.value)
    await wait.task.value
  }

  @Test func whenAnotherPageReportsReady_shouldKeepWaiting() async {
    // A page left over from an earlier landing hides too, under its own id.
    let scrub = CarouselScrub()
    scrub.pageReadyId = otherCardId
    let clock = TestClock()
    let wait = startWaiting(for: cardId, on: scrub, clock: clock)

    await clock.advance(by: .milliseconds(104))

    #expect(wait.didReturn.value == false)
    wait.task.cancel()
    await wait.task.value
  }

  @Test func whenThePageNeverReports_shouldGiveUpAfter14Polls() async {
    let scrub = CarouselScrub()
    let clock = TestClock()
    let wait = startWaiting(for: cardId, on: scrub, clock: clock)

    await clock.advance(by: .milliseconds(104))
    #expect(wait.didReturn.value == false)

    await clock.advance(by: .milliseconds(8))
    await Task.megaYield()

    #expect(wait.didReturn.value)
    await wait.task.value
  }

  @Test(.timeLimit(.minutes(1)))
  func whenTheLandingIsCancelled_shouldNotWaitOutTheTimeout() async {
    // A new scrub cancels the landing, and its wait must not hold the next one up.
    let scrub = CarouselScrub()
    let clock = TestClock()
    let wait = startWaiting(for: cardId, on: scrub, clock: clock)
    await Task.megaYield()

    wait.task.cancel()
    await wait.task.value

    #expect(wait.didReturn.value)
  }
}
