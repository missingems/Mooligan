import XCTest

/// The price history section on card detail: the latest-price summary, the
/// cart dropdown of purchase links, and recovering from a failed load.
final class PriceHistoryUITests: UITestCase {
  func testSummaryShowsTheLatestPrices() {
    let page = openPriceHistory()

    let summary = page.descendants(matching: .any)["priceHistory.summary"].firstMatch
    assert(pollExists(summary), "the price summary should render")
    assert(waitForPrices(in: summary), "the summary should show loaded prices, not placeholders")
  }

  func testBuyListsPurchaseLinksAndClosesOnScroll() {
    let page = openPriceHistory()
    let cart = page.buttons["priceHistory.cart"].firstMatch

    cart.tap()

    let ids = [
      "priceHistory.purchaseLink.tcgplayer.normal",
      "priceHistory.purchaseLink.tcgplayer.foil",
      "priceHistory.purchaseLink.cardkingdom.normal",
      "priceHistory.purchaseLink.cardkingdom.foil",
    ]
    for id in ids {
      assert(pollExists(page.buttons[id].firstMatch), "\(id) should be listed")
    }

    dragUp()

    expectToDisappear(page.buttons[ids[0]].firstMatch, named: "purchase links")
    assert(pollExists(page.buttons["priceHistory.cart"].firstMatch), "Buy should come back once the dropdown closes")
  }

  func testSwipingAcrossTheChartPagesInsteadOfScrubbing() {
    let page = openPriceHistory()
    let chart = chartPoint(in: page)

    let next = waitFor("cardDetail.page.02")
    refute(next.isHittable, "the next card should start off screen")

    chart(0.85).press(forDuration: 0.01, thenDragTo: chart(0.1), withVelocity: .fast, thenHoldForDuration: 0.0)

    var paged = false
    for _ in 0..<20 where paged == false {
      paged = next.isHittable
      if paged == false { Thread.sleep(forTimeInterval: 0.5) }
    }
    assert(paged, "a quick swipe over the chart should page to the next card")
  }

  func testHoldingThenDraggingScrubsWithoutPaging() {
    let page = openPriceHistory()
    let chart = chartPoint(in: page)

    chart(0.8).press(forDuration: 0.8, thenDragTo: chart(0.2), withVelocity: .slow, thenHoldForDuration: 0.5)
    Thread.sleep(forTimeInterval: 1.0)

    assert(page.isHittable, "a press-and-drag on the chart should scrub, not page away")
    refute(waitFor("cardDetail.page.02").isHittable, "the next card should stay off screen")
  }

  private func chartPoint(in page: XCUIElement) -> (CGFloat) -> XCUICoordinate {
    let cart = page.buttons["priceHistory.cart"].firstMatch
    let middle = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
    for _ in 0..<6 where cart.frame.minY > app.frame.height * 0.3 {
      middle.press(forDuration: 0.05, thenDragTo: middle.withOffset(CGVector(dx: 0.0, dy: -160.0)), withVelocity: .slow, thenHoldForDuration: 0.4)
    }
    let y = cart.frame.maxY + 150.0
    let origin = app.coordinate(withNormalizedOffset: .zero)
    let width = app.frame.width
    return { fraction in origin.withOffset(CGVector(dx: width * fraction, dy: y)) }
  }

  private func waitForPrices(in summary: XCUIElement) -> Bool {
    for _ in 0..<60 {
      let label = summary.label
      if label.contains("$"), label.contains("$0.00") == false { return true }
      Thread.sleep(forTimeInterval: 0.5)
    }
    return false
  }
}

/// Launches with a price feed that fails the first three requests per card, so
/// the automatic retries run out and the Retry button has to recover it.
final class PriceHistoryRecoveryUITests: UITestCase {
  override var additionalLaunchArguments: [String] { ["-uiTestPriceHistoryFailure"] }

  func testRetryRecoversAfterAutomaticRetriesRunOut() {
    let page = openPriceHistory()

    let retry = page.buttons["priceHistory.retry"].firstMatch
    assert(pollExists(retry, tries: 120), "Retry should appear once the automatic retries fail")

    retry.tap()

    expectToDisappear(retry, named: "Retry button")
    let summary = page.descendants(matching: .any)["priceHistory.summary"].firstMatch
    assert(pollExists(summary), "the price summary should render")

    var loaded = false
    for _ in 0..<60 where loaded == false {
      let label = summary.label
      loaded = label.contains("$") && label.contains("$0.00") == false && label.contains("—") == false
      if loaded == false { Thread.sleep(forTimeInterval: 0.5) }
    }
    assert(loaded, "prices should load after retrying")
  }
}

extension UITestCase {
  /// Opens the first card and scrolls until the price history cart is on screen.
  @discardableResult
  func openPriceHistory() -> XCUIElement {
    openFirstCard()
    let page = waitFor("cardDetail.page.01")
    scrollUpTo(page.buttons["priceHistory.cart"].firstMatch, named: "price history cart button")
    return page
  }
}
