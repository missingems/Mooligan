import XCTest

/// Shared base for the feature UI tests.
///
/// `@MainActor` because every `XCUIElement` / `XCUIApplication` member is main
/// actor-isolated under Swift 6; the subclasses inherit the isolation.
///
/// Every test launches the app with `-uiTestMode`, which routes the app through
/// `UITestSupport` — mock network clients, inert bulk sync — so the flows below
/// are deterministic and offline. Card fixtures are "Test Card 01"…"Test Card 60"
/// with matching collector numbers, 12 per page.
@MainActor
class UITestCase: XCTestCase {
  var app: XCUIApplication!

  /// Generous, because a cold launch on a CI simulator plus the first mock
  /// query can be slow.
  let timeout: TimeInterval = 30

  override func setUp() async throws {
    try await super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["-uiTestMode"]
    app.launch()
  }

  override func tearDown() async throws {
    app = nil
    try await super.tearDown()
  }

  // MARK: - Assertions
  //
  // `XCTAssert*` take a nonisolated `@autoclosure`, so an `XCUIElement` member
  // read inside one warns under Swift 6. These wrappers take an already-evaluated
  // value instead.

  func assert(_ condition: Bool, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertTrue(condition, message, file: file, line: line)
  }

  func refute(_ condition: Bool, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertFalse(condition, message, file: file, line: line)
  }

  // MARK: - Element lookup

  /// Matches an accessibility identifier regardless of the resolved element
  /// type. Fine for `.exists` polling loops; for `waitForExistence` prefer a
  /// typed query (`card(_:)`, `app.buttons[...]`, …) — the `.any` query is
  /// unreliable there.
  func element(_ identifier: String) -> XCUIElement {
    app.descendants(matching: .any)[identifier]
  }

  /// A card cell in the set-detail grid or the card pager. Cards surface as
  /// `.other` elements; a typed query polls reliably.
  func card(_ number: Int) -> XCUIElement {
    app.otherElements[String(format: "setDetail.card.%02d", number)]
  }

  /// Types `text` into `field` and verifies it landed — `XCUIElement.typeText`
  /// intermittently drops characters into SwiftUI text fields, so retry.
  func type(_ text: String, into field: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
    for _ in 0..<4 {
      field.tap()
      if let current = field.value as? String, current.isEmpty == false {
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
      }
      field.typeText(text)
      if (field.value as? String) == text { return }
    }
    let got = field.value as? String ?? "nil"
    XCTFail("could not type \"\(text)\" (got \"\(got)\")", file: file, line: line)
  }

  @discardableResult
  func waitFor(_ identifier: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
    let el = element(identifier)
    let appeared = el.waitForExistence(timeout: timeout ?? self.timeout)
    assert(appeared, "\(identifier) never appeared", file: file, line: line)
    return el
  }

  /// Polls `.exists` directly — reliable when `waitForExistence` stalls because
  /// the app never signals "idle" (e.g. a spinner is animating).
  func pollExists(_ el: XCUIElement, tries: Int = 40) -> Bool {
    for _ in 0..<tries {
      if el.exists { return true }
      Thread.sleep(forTimeInterval: 0.5)
    }
    return false
  }

  func expectToDisappear(_ el: XCUIElement, named name: String, file: StaticString = #filePath, line: UInt = #line) {
    let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: el)
    _ = XCTWaiter().wait(for: [gone], timeout: timeout)
    refute(el.exists, "\(name) should be gone", file: file, line: line)
  }

  /// A firm upward drag through the middle of the screen. More reliable than
  /// `XCUIElement.swipeUp()` for SwiftUI scroll views, which sometimes expose
  /// several elements for one identifier.
  func dragUp() {
    let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18))
    start.press(forDuration: 0.05, thenDragTo: end)
  }

  /// Drags up until `target` is hittable, or fails.
  func scrollUpTo(_ target: XCUIElement, named name: String, maxSwipes: Int = 12, file: StaticString = #filePath, line: UInt = #line) {
    for _ in 0..<maxSwipes {
      if target.exists && target.isHittable { return }
      dragUp()
    }
    assert(
      target.exists && target.isHittable,
      "\(name) not reachable after \(maxSwipes) drags",
      file: file,
      line: line
    )
  }

  // MARK: - Navigation helpers

  /// From the Browse tab, opens the first mock set ("Final Fantasy", code FIN).
  func openFirstSet() {
    waitFor("browse.setList")
    waitFor("browse.setRow.FIN").tap()
    waitFor("setDetail.cardGrid")
  }

  /// Browse → first set → first card, landing on the horizontal card pager.
  func openFirstCard() {
    openFirstSet()
    let firstCard = card(1)
    assert(firstCard.waitForExistence(timeout: timeout), "first card never appeared")
    firstCard.tap()
    waitFor("cardDetail.pager")
  }
}
