import XCTest

/// The information row on card detail: the pull odds tile, and the pager of explanations a tile
/// opens.
final class InformationInsightUITests: UITestCase {
  func testTappingTheOddsOpensThePagerSwipingPagesOnAndCloseDismissesIt() {
    openFirstCard()
    let page = waitFor("cardDetail.page.01")
    let odds = page.descendants(matching: .any)["cardDetail.widget.pullOdds"].firstMatch
    assert(pollExists(odds), "the pull odds tile should render once the odds land")
    for _ in 0..<12 where odds.frame.maxY > app.frame.height * 0.8 {
      dragUp()
    }
    // The estimate across the test set's Play and Collector Boosters.
    assert(odds.label.contains("About 164 packs"), "the tile should quote the estimate, got \(odds.label)")

    odds.tap()

    // The pager covers the whole screen, the card's bars included, and opens on the tapped tile.
    let pullRate = app.staticTexts["cardDetail.insight.title.pullOdds"].firstMatch
    assert(pollExists(pullRate), "tapping the odds should open their explanation")
    assert(pullRate.label == "Pull Rate", "the pager should open on the pull rate, got \(pullRate.label)")
    assert(
      pollExists(app.staticTexts["cardDetail.insight.elaboration.pullOdds"].firstMatch),
      "the on-device explanation should be written under the facts"
    )

    // Swiping moves on to the next tile of the row.
    pullRate.swipeLeft()
    let collectorNumber = app.staticTexts["cardDetail.insight.title.collectorNumber"].firstMatch
    var paged = false
    for _ in 0..<20 where paged == false {
      paged = collectorNumber.exists && collectorNumber.isHittable
      if paged == false { Thread.sleep(forTimeInterval: 0.25) }
    }
    assert(paged, "a swipe should page to the collector number")

    app.buttons["cardDetail.insight.close"].firstMatch.tap()

    expectToDisappear(collectorNumber, named: "Insight pager")
    assert(pollExists(odds), "the odds tile should still be there")
  }
}
