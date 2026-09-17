import XCTest

/// The market price section on card detail: the latest prices and their sheets, scrubbing
/// versus paging over the chart, and recovering from a failed load.
final class PriceHistoryUITests: UITestCase {
  func testToolbarShowsTheLatestPricesAndBuyBack() {
    let page = openPriceHistory()

    assert(waitForPrices(in: firstPrice(in: page)), "the toolbar should show loaded prices, not placeholders")
    assert(pollExists(page.descendants(matching: .any)["priceHistory.buyBack"].firstMatch), "the buy back ratio should render")
  }

  func testTappingBuyBackOpensItsBreakdownSheetAndCloseDismissesIt() {
    let page = openPriceHistory()
    let buyBack = page.descendants(matching: .any)["priceHistory.buyBack"].firstMatch

    var ratioLoaded = false
    for _ in 0..<40 where ratioLoaded == false {
      ratioLoaded = buyBack.label.contains("%")
      if ratioLoaded == false { Thread.sleep(forTimeInterval: 0.5) }
    }
    assert(ratioLoaded, "the buy back ratio should show a percentage, got \(buyBack.label)")

    buyBack.tap()

    // The sheet is presented over the page, not inside it.
    let breakdown = app.descendants(matching: .any)["priceHistory.buyBack.breakdown"].firstMatch
    assert(pollExists(breakdown), "tapping buy back should open its breakdown sheet")
    assert(breakdown.label.contains("Regular"), "the breakdown should list the regular finish, got \(breakdown.label)")
    let source = app.descendants(matching: .any)["priceHistory.buyBack.source"].firstMatch
    assert(pollExists(source), "the sheet should name the vendor")
    assert(source.label.contains("Card Kingdom"), "the vendor should be Card Kingdom, got \(source.label)")
    assert(pollExists(app.buttons["priceHistory.buyBack.sell"].firstMatch), "the sheet should link to the vendor's buylist")

    app.buttons["priceHistory.buyBack.close"].firstMatch.tap()

    expectToDisappear(breakdown, named: "Buy back sheet")
    assert(pollExists(buyBack), "the buy back capsule should still be there")
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
    // Buy back is always in the toolbar's last row, whether it has one row or two.
    let buyBack = page.descendants(matching: .any)["priceHistory.buyBack"].firstMatch
    let middle = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
    for _ in 0..<6 where buyBack.frame.minY > app.frame.height * 0.6 {
      middle.press(forDuration: 0.05, thenDragTo: middle.withOffset(CGVector(dx: 0.0, dy: -160.0)), withVelocity: .slow, thenHoldForDuration: 0.4)
    }
    let chart = page.descendants(matching: .any)["priceHistory.chart"].firstMatch
    assert(pollExists(chart), "the chart should be on screen")
    let y = chart.frame.midY
    let origin = app.coordinate(withNormalizedOffset: .zero)
    let width = app.frame.width
    return { fraction in origin.withOffset(CGVector(dx: width * fraction, dy: y)) }
  }

  private func waitForPrices(in price: XCUIElement) -> Bool {
    for _ in 0..<60 {
      let label = price.label
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
    let price = firstPrice(in: page)
    assert(pollExists(price), "a finish price should render")

    var loaded = false
    for _ in 0..<60 where loaded == false {
      let label = price.label
      loaded = label.contains("$") && label.contains("$0.00") == false && label.contains("—") == false && label.contains("N/A") == false
      if loaded == false { Thread.sleep(forTimeInterval: 0.5) }
    }
    assert(loaded, "prices should load after retrying")
  }
}

extension UITestCase {
  /// Opens the first card and scrolls until the market price toolbar is on screen.
  ///
  /// This waits for the first price's frame to come on screen instead of using `scrollUpTo`.
  @discardableResult
  func openPriceHistory(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
    openFirstCard()
    let page = waitFor("cardDetail.page.01")
    let price = firstPrice(in: page)
    assert(pollExists(price), "a finish price should render", file: file, line: line)
    for _ in 0..<12 where price.frame.maxY > app.frame.height * 0.85 {
      dragUp()
    }
    assert(price.frame.maxY <= app.frame.height * 0.85, "the finish prices should be on screen", file: file, line: line)
    return page
  }

  /// The first finish's price. Which finishes show depends on the card, and on what the feed charts
  /// once it loads, so this matches any of them.
  func firstPrice(in page: XCUIElement) -> XCUIElement {
    page.descendants(matching: .any)
      .matching(NSPredicate(format: "identifier BEGINSWITH %@", "priceHistory.price."))
      .firstMatch
  }
}
