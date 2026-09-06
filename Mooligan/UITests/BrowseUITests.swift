import XCTest

/// Browse tab: the set list loads, and the search field filters it.
final class BrowseUITests: UITestCase {
  func testSetListLoads() {
    waitFor("browse.setList")

    // Mock sets: FIN (Final Fantasy), TDM (Tarkir: Dragonstorm), MKM, WOE, LHIC.
    assert(waitFor("browse.setRow.FIN").exists, "FIN row should load")
    assert(element("browse.setRow.TDM").exists, "TDM row should load")
  }

  func testSearchFiltersSetList() {
    waitFor("browse.setList")
    assert(element("browse.setRow.FIN").exists, "FIN row should be present before filtering")

    let search = app.searchFields.firstMatch
    assert(search.waitForExistence(timeout: timeout), "search field missing")
    type("Tarkir", into: search)

    // Tarkir stays, Final Fantasy is filtered out.
    assert(pollExists(element("browse.setRow.TDM")), "Tarkir row should survive the filter")
    expectToDisappear(element("browse.setRow.FIN"), named: "Final Fantasy row")

    // Clearing restores the full list. `.searchable` shows a Cancel button while
    // the field is active.
    let cancel = app.buttons["Cancel"]
    if cancel.exists {
      cancel.tap()
    } else {
      search.buttons.firstMatch.tap() // the clear (x) button inside the field
    }

    assert(
      pollExists(element("browse.setRow.FIN")),
      "Final Fantasy row should return after clearing the search"
    )
  }
}
