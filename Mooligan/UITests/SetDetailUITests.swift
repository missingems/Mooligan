import XCTest

/// Set detail (the `Query` feature): grid loads and scrolls, pagination loads
/// more, the colour filter re-queries, and in-set search narrows the grid.
final class SetDetailUITests: UITestCase {
  func testCardGridLoadsAndScrolls() {
    openFirstSet()

    waitFor("setDetail.cardGrid")
    assert(card(1).waitForExistence(timeout: timeout), "first card never appeared")

    // Card 12 is the last of page one — reachable by scrolling, no new fetch.
    scrollUpTo(card(12), named: "card 12")
  }

  func testPaginationLoadsMore() {
    openFirstSet()

    waitFor("setDetail.cardGrid")
    assert(card(1).waitForExistence(timeout: timeout), "first card never appeared")
    scrollUpTo(card(12), named: "card 12")

    // Card 20 only exists once page two has been fetched and appended.
    scrollUpTo(card(20), named: "card 20 (page 2)", maxSwipes: 20)
  }

  func testColourFilterRequeries() {
    openFirstSet()

    waitFor("setDetail.cardGrid")
    assert(card(1).waitForExistence(timeout: timeout), "first card never appeared")
    scrollUpTo(card(20), named: "card 20 (page 2)", maxSwipes: 20)

    element("setDetail.filter.color").firstMatch.tap()
    let option = app.buttons["setDetail.filterOption.White"]
    assert(option.waitForExistence(timeout: timeout), "colour option missing")
    option.tap()

    // The colour selection collapses the corpus to 6 cards, so 20 disappears
    // and 01 is still there.
    assert(card(1).waitForExistence(timeout: timeout), "first card should remain")
    expectToDisappear(card(20), named: "card 20")
  }

  func testInSetSearchNarrowsResults() {
    openFirstSet()

    waitFor("setDetail.cardGrid")
    assert(card(1).waitForExistence(timeout: timeout), "first card never appeared")

    app.buttons["setDetail.searchField.toggle"].firstMatch.tap()
    let field = app.textFields["setDetail.searchField"]
    assert(field.waitForExistence(timeout: timeout), "in-set search field missing")

    // "07" is a substring of "Test Card 07" only.
    type("07", into: field)

    // Grid narrows to the single match: card 01 goes, card 07 stays. Poll
    // `.exists` directly — `waitForExistence` stalls while the search bar's
    // spinner animates and the keyboard is up.
    expectToDisappear(card(1), named: "card 01")
    assert(pollExists(card(7)), "the matching card should be shown")
  }
}
