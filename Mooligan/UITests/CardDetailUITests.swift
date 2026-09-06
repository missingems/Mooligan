import XCTest

/// Card detail (the `CardDetail` feature): vertical scroll of a card's detail
/// content, and horizontal paging between cards.
final class CardDetailUITests: UITestCase {
  func testHorizontalPaging() {
    openFirstCard()

    let pager = waitFor("cardDetail.pager")
    assert(waitFor("cardDetail.page.01").isHittable, "first page should be visible")

    pager.swipeLeft()

    assert(
      waitFor("cardDetail.page.02").isHittable,
      "swiping left should page to the next card"
    )
  }

  func testVerticalScroll() {
    openFirstCard()

    let page = waitFor("cardDetail.page.01")

    // "Information" is a section header just under the card image; "Rulings" is
    // the last row. Both render up front (the detail ScrollView isn't lazy), so
    // assert the content actually moves: the header scrolls up off-screen and
    // the last row scrolls up into the viewport. Scope to page 01 — the pager
    // keeps the neighbouring page's copies of these labels in the tree too.
    let header = page.staticTexts["Information"].firstMatch
    let rulings = page.staticTexts["Rulings"].firstMatch
    assert(header.waitForExistence(timeout: timeout), "Information header should render")

    let headerStartY = header.frame.minY
    let rulingsStartY = rulings.frame.minY

    for _ in 0..<5 { page.swipeUp() }

    let headerEndY = header.frame.minY
    let rulingsEndY = rulings.frame.minY
    let viewportHeight = page.frame.height

    XCTAssertLessThan(headerEndY, headerStartY - 100, "the detail content should have scrolled up")
    XCTAssertLessThan(rulingsEndY, rulingsStartY - 100, "the last row should have scrolled up too")
    XCTAssertLessThan(rulingsEndY, viewportHeight, "the last row should be within the viewport after scrolling down")
  }
}
