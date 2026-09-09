import XCTest

/// Pack opening: the shelf, the tear, and the swipeable reveal.
///
/// The reveal is a hand-rolled card stack rather than a scroll view, so its
/// gesture has no framework behaviour to fall back on and is worth driving for
/// real: a drag past the threshold has to deal the next card, a drag short of
/// it has to leave the stack where it was, and rewind has to put a card back.
///
/// Drags go through screen coordinates rather than the stack's own element.
/// The stack is a single accessibility container and SwiftUI does not surface
/// it reliably enough to hang a gesture off, but the card is centred, so
/// normalised offsets land on it just as well.
final class PackOpeningUITests: UITestCase {
  /// How far through the pack the reveal is, read off the header ("3 / 14").
  private func position() -> Int? {
    let label = app.staticTexts["packOpening.position"].label
    return Int(label.split(separator: "/").first?.trimmingCharacters(in: .whitespaces) ?? "")
  }

  /// Shelf → first pack → torn open → cards on screen.
  ///
  /// Every step uses a typed query. `UITestCase.waitFor` goes through
  /// `descendants(matching: .any)`, which resolves against this screen even
  /// when the element is not there, so a `.any` wait here reports success and
  /// leaves the rest of the test drawing conclusions from the shelf.
  private func openFirstPack() {
    app.buttons["Packs"].tap()

    let slot = app.buttons["packOpening.slot.FIN-play"]
    assert(slot.waitForExistence(timeout: timeout), "FIN play booster should be on the shelf")
    slot.tap()

    // `PackTearView` ignores its children and takes the button trait, so the
    // sealed pack comes through as a button.
    let pack = app.buttons["packOpening.tear"]
    assert(pack.waitForExistence(timeout: timeout), "the sealed pack should be presented")

    // The tear is a right-to-left drag across most of the pack's width; there
    // is no tap that stands in for it.
    let start = pack.coordinate(withNormalizedOffset: CGVector(dx: 0.82, dy: 0.36))
    let end = pack.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.36))
    start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)

    assert(
      app.staticTexts["packOpening.position"].waitForExistence(timeout: timeout),
      "the reveal header should show how far through the pack we are"
    )
  }

  /// Drags the top card left by `fraction` of the screen's width, starting in
  /// the card's upper half so the grip-dependent tilt is exercised too.
  private func dragTopCard(by fraction: CGFloat, holdFor hold: TimeInterval = 0.1) {
    let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.38))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5 - fraction, dy: 0.38))
    start.press(forDuration: 0.15, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: hold)
  }

  private func attachScreenshot(named name: String) {
    XCTContext.runActivity(named: name) { activity in
      let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
      shot.name = name
      shot.lifetime = .keepAlways
      activity.add(shot)
    }
  }

  func testSwipeDealsTheNextCard() {
    openFirstPack()
    attachScreenshot(named: "Reveal, first card")

    guard let first = position() else { return XCTFail("could not read the header position") }
    assert(first == 1, "the pack should open on its first card, got \(first)")

    // Held partway so the tilt and the stack closing up behind are on screen
    // long enough to be caught, then carried well past the threshold.
    dragTopCard(by: 0.4, holdFor: 2.5)
    Thread.sleep(forTimeInterval: 0.8)

    guard let dealt = position() else { return XCTFail("no position after the swipe") }
    assert(dealt == 2, "a firm swipe should deal the next card, got \(dealt)")
    attachScreenshot(named: "Reveal, after one swipe")
  }

  func testShortDragSpringsBack() {
    openFirstPack()

    guard let before = position() else { return XCTFail("no starting position") }

    // A nudge, nowhere near the threshold.
    dragTopCard(by: 0.04)
    Thread.sleep(forTimeInterval: 1)

    guard let after = position() else { return XCTFail("no position after the nudge") }
    assert(after == before, "a short drag should spring back, moved \(before) → \(after)")
  }

  func testRewindPutsTheLastCardBack() {
    openFirstPack()

    dragTopCard(by: 0.4)
    Thread.sleep(forTimeInterval: 0.8)
    guard position() == 2 else {
      return XCTFail("expected to be on card 2, got \(position().map(String.init) ?? "nil")")
    }

    let rewind = app.buttons["packOpening.rewind"]
    assert(rewind.waitForExistence(timeout: timeout), "rewind should appear once a card has gone")
    rewind.tap()
    Thread.sleep(forTimeInterval: 1)

    guard let back = position() else { return XCTFail("no position after rewinding") }
    assert(back == 1, "rewind should put the card back, got \(back)")
    attachScreenshot(named: "Reveal, after rewinding")
  }
}
