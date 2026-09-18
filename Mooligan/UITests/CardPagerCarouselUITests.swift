import XCTest

/// The card pager's thumbnail strip in the bottom bar (`CardPagerCarousel`): it shows the cards, a
/// tap on a thumbnail pages to that card, a scrub along it lands on the card under the lens, a flick
/// lands where the strip coasts to, and the strip keeps the pager's card under the lens.
final class CardPagerCarouselUITests: UITestCase {
  func testStripShowsTheCardsInTheBottomBar() {
    openFirstCard()

    assert(pollExists(strip), "the thumbnail strip should be in the bottom bar")
    assert(strip.frame.minY > app.frame.height * 0.8, "the strip should sit at the bottom of the screen")
    // The blurred ends are decoration. Left in the tree they picked up the strip's identifier and
    // came first, so a lookup by identifier pressed the leading blur instead of the lens.
    let named = app.descendants(matching: .any).matching(identifier: "cardDetail.carousel")
    assert(named.count == 1, "only the strip should carry its identifier (found \(named.count))")
    assert(pollExists(element("cardDetail.carousel.01").firstMatch), "the open card should have a thumbnail")
    assert(pollExists(element("cardDetail.carousel.02").firstMatch), "the next card's thumbnail should be beside it")
  }

  func testTappingAThumbnailPagesToThatCard() {
    openFirstCard()
    assert(waitUntilOnScreen(1), "the first card's page should open")

    // Two along rather than the neighbour, so the pager has to jump rather than page once.
    let thumbnail = element("cardDetail.carousel.03").firstMatch
    assert(pollExists(thumbnail), "the third card's thumbnail should be in the strip")
    thumbnail.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

    assert(waitUntilOnScreen(3), "tapping a thumbnail should page to its card")
    refute(isOnScreen(1), "the first card should have paged away")
  }

  func testScrubbingTheStripLandsOnAnotherCard() {
    openFirstCard()
    assert(waitUntilOnScreen(1), "the first card's page should open")

    assert(pollExists(strip), "the thumbnail strip should be in the bottom bar")

    // Press under the lens and drag a couple of 48pt tiles along, then hold still before letting
    // go, so the card lands where the strip stops rather than after a coast.
    let lens = strip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    lens.press(
      forDuration: 0.3,
      thenDragTo: lens.withOffset(CGVector(dx: -120, dy: 0)),
      withVelocity: .slow,
      thenHoldForDuration: 0.5
    )

    // Which card stops under the lens depends on the drag's slop, so any after the first will do.
    var landed: Int?
    for _ in 0..<20 where landed == nil {
      landed = (2...6).first { isOnScreen($0) }
      if landed == nil { Thread.sleep(forTimeInterval: 0.5) }
    }
    assert(landed != nil, "letting go of a scrub should land the pager on the card under the lens")
    refute(isOnScreen(1), "the first card should have been left behind")
    if let landed {
      assert(waitUntilUnderTheLens(landed), "the strip should rest on the card it landed on")
    }
  }

  /// A flick lands where the strip stops coasting, not on the card the finger let go over. The
  /// strip's own phase change reads no speed on a fast release, so this rests on the finger's speed
  /// from the tracker.
  func testFlickingTheStripLandsWhereItCoastsTo() {
    openFirstCard()
    assert(waitUntilOnScreen(1), "the first card's page should open")
    assert(waitUntilUnderTheLens(1), "the open card should start under the lens")

    // Under two 48pt tiles once the drag's slop is taken, so the finger lets go over 02 at most, and
    // without its speed the card lands there, or stays on 01. The simulator's release comes out at
    // one of two speeds, and the strip coasts on to 03 or 05.
    let lens = strip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    lens.press(
      forDuration: 0.05,
      thenDragTo: lens.withOffset(CGVector(dx: -100, dy: 0)),
      withVelocity: XCUIGestureVelocity(rawValue: 2500),
      thenHoldForDuration: 0
    )

    var landed: Int?
    for _ in 0..<20 where landed == nil {
      landed = (2...12).first { isOnScreen($0) }
      if landed == nil { Thread.sleep(forTimeInterval: 0.5) }
    }
    assert(
      (landed ?? 0) >= 3,
      "a flick should coast past the card the finger let go over before it lands (landed on \(landed.map(String.init) ?? "none"))"
    )
  }

  func testStripFollowsThePagerWhenItIsSwiped() {
    openFirstCard()
    assert(waitUntilOnScreen(1), "the first card's page should open")
    assert(waitUntilUnderTheLens(1), "the open card should start under the lens")

    element("cardDetail.pager").firstMatch.swipeLeft()

    assert(waitUntilOnScreen(2), "swiping the pager should page to the next card")
    assert(waitUntilUnderTheLens(2), "the strip should move the next card under the lens")
  }

  func testStripOpensOnTheCardOpened() {
    // Not the first card, so a strip left at its start would show the wrong one.
    openFirstSet()
    let third = card(3)
    assert(third.waitForExistence(timeout: timeout), "the third card never appeared")
    third.tap()
    waitFor("cardDetail.pager")

    assert(waitUntilOnScreen(3), "the third card's page should open")
    assert(waitUntilUnderTheLens(3), "the strip should open with the card opened under the lens")
  }

  /// The strip's scroll view, whose middle is the lens.
  private var strip: XCUIElement {
    app.scrollViews["cardDetail.carousel"].firstMatch
  }

  /// Whether this card's thumbnail sits under the lens, in the middle of the strip. The tile there
  /// neither leans nor curls, so its frame is exact.
  private func isUnderTheLens(_ number: Int) -> Bool {
    let thumbnail = element(String(format: "cardDetail.carousel.%02d", number)).firstMatch
    return thumbnail.exists && strip.exists && abs(thumbnail.frame.midX - strip.frame.midX) < 2
  }

  private func waitUntilUnderTheLens(_ number: Int) -> Bool {
    for _ in 0..<20 {
      if isUnderTheLens(number) { return true }
      Thread.sleep(forTimeInterval: 0.5)
    }
    return false
  }

  /// Whether this card's page is the one on screen. The pager keeps the pages either side built, so
  /// being in the tree is not enough: only the page on screen is hittable.
  private func isOnScreen(_ number: Int) -> Bool {
    let page = element(String(format: "cardDetail.page.%02d", number)).firstMatch
    return page.exists && page.isHittable
  }

  private func waitUntilOnScreen(_ number: Int) -> Bool {
    for _ in 0..<20 {
      if isOnScreen(number) { return true }
      Thread.sleep(forTimeInterval: 0.5)
    }
    return false
  }
}
