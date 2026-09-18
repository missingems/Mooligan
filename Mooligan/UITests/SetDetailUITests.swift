import XCTest

/// Set detail (the `Query` feature): grid loads and scrolls, pagination loads
/// more, the filter bar sits over the grid and its chips pick a colour, a type
/// and a sort, in-set search narrows the grid, and the bottom bar's pack button
/// opens the set's packs.
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

    let field = app.searchFields.firstMatch
    assert(field.waitForExistence(timeout: timeout), "in-set search field missing")

    // "07" is a substring of "Test Card 07" only.
    type("07", into: field)

    // Grid narrows to the single match: card 01 goes, card 07 stays. Poll
    // `.exists` directly — `waitForExistence` stalls while the search bar's
    // spinner animates and the keyboard is up.
    expectToDisappear(card(1), named: "card 01")
    assert(pollExists(card(7)), "the matching card should be shown")
  }

  func testFilterChipsSitAboveTheGridAndStayWhileItScrolls() {
    openFirstSet()

    let first = card(1).firstMatch
    assert(first.waitForExistence(timeout: timeout), "first card never appeared")

    var restingFrames: [String: CGRect] = [:]
    for name in ["color", "type", "sort"] {
      let chip = element("setDetail.filter.\(name)").firstMatch
      assert(pollExists(chip), "the \(name) chip should be in the filter bar")
      assert(chip.isHittable, "the \(name) chip should be on screen")

      // Polled: the bar animates in with the first page, and the grid moves down to make room.
      var isAboveTheGrid = false
      for _ in 0..<10 where isAboveTheGrid == false {
        isAboveTheGrid = chip.frame.maxY <= first.frame.minY
        if isAboveTheGrid == false { Thread.sleep(forTimeInterval: 0.5) }
      }
      assert(isAboveTheGrid, "the \(name) chip should sit above the first row of cards")
      restingFrames[name] = chip.frame
    }

    // The bar is pinned over the grid, not scrolled away with it. Checked by where the chips are
    // rather than `isHittable`, which reads false once cards pass under the bar, though a tap still
    // reaches the chip there (the colour filter test taps it after scrolling).
    scrollUpTo(card(12), named: "card 12")
    refute(first.exists && first.isHittable, "the grid should have scrolled the first row away")

    for name in ["color", "type", "sort"] {
      let chip = element("setDetail.filter.\(name)").firstMatch
      let resting = restingFrames[name] ?? .null
      assert(chip.exists, "the \(name) chip should stay in the filter bar as the grid scrolls")
      assert(
        abs(chip.frame.minY - resting.minY) < 1 && abs(chip.frame.minX - resting.minX) < 1,
        "the \(name) chip should stay where it was as the grid scrolls (was \(resting), now \(chip.frame))"
      )
    }
  }

  func testTypeChipPicksACardType() {
    openFirstSet()
    assert(card(1).waitForExistence(timeout: timeout), "first card never appeared")

    let chip = element("setDetail.filter.type").firstMatch
    assert(pollExists(chip), "the type chip should be in the filter bar")
    refute(chip.label.contains("Creature"), "a set should open showing every card type")
    chip.tap()

    let creature = app.buttons["filterOption.Creature"]
    assert(creature.waitForExistence(timeout: timeout), "the type chip should list card types")
    assert(app.buttons["filterOption.Land"].exists, "every card type should be offered")

    // With one type picked, the chip names it.
    creature.tap()
    assert(waitForLabel(of: chip, toContain: "Creature"), "the type chip should show the type picked (was \"\(chip.label)\")")
  }

  func testSortChipPicksASortMode() {
    openFirstSet()
    assert(card(1).waitForExistence(timeout: timeout), "first card never appeared")

    let chip = element("setDetail.filter.sort").firstMatch
    assert(pollExists(chip), "the sort chip should be in the filter bar")
    refute(chip.label.contains("Price"), "a set should open sorted by something other than price")
    chip.tap()

    let price = app.buttons["filterOption.Price"]
    assert(price.waitForExistence(timeout: timeout), "the sort chip should list sort modes")
    assert(app.buttons["filterOption.Rarity"].exists, "every sort mode should be offered")

    price.tap()
    assert(waitForLabel(of: chip, toContain: "Price"), "the sort chip should show the sort picked (was \"\(chip.label)\")")
  }

  func testPackButtonIsDisabledForASetNeverSoldInPacks() {
    // The Final Fantasy mock is filed as an Alchemy set, which never had a pack to open.
    openFirstSet()

    let pack = app.buttons["setDetail.openPack"].firstMatch
    assert(pack.waitForExistence(timeout: timeout), "the pack button should be in the bottom bar")
    refute(pack.isEnabled, "a set never sold in packs should have nothing to open")
  }

  func testPackButtonOffersTheSetsPacksAndOpensOne() {
    // Tarkir: Dragonstorm, a 2025 expansion: Play and Collector Boosters, and no Draft Boosters,
    // which were retired the year before.
    openSet("TDM")
    assert(card(1).waitForExistence(timeout: timeout), "first card never appeared")

    let pack = app.buttons["setDetail.openPack"].firstMatch
    assert(pack.waitForExistence(timeout: timeout), "the pack button should be in the bottom bar")
    assert(pack.isEnabled, "a set sold in packs should have its pack button live")

    pack.tap()

    let play = packOption("play", titled: "Open Play Booster")
    assert(pollExists(play), "the menu should offer a Play Booster")
    assert(pollExists(packOption("collector", titled: "Open Collector Booster")), "the menu should offer a Collector Booster")
    refute(packOption("draft", titled: "Open Draft Booster").exists, "the menu should not offer a Draft Booster")

    play.tap()

    // Any of the session's elements will do: the session's own identifier is on its container, so
    // which children carry it, and whether it hides theirs, is up to SwiftUI.
    let session = app.descendants(matching: .any)
      .matching(NSPredicate(format: "identifier BEGINSWITH %@", "packOpening."))
      .firstMatch
    assert(pollExists(session), "choosing a pack should open it")
  }

  /// Polls a chip's label, which changes a beat after the pick as the bar animates.
  private func waitForLabel(of chip: XCUIElement, toContain text: String) -> Bool {
    for _ in 0..<20 {
      if chip.exists, chip.label.contains(text) { return true }
      Thread.sleep(forTimeInterval: 0.5)
    }
    return false
  }

  /// A pack in the pack button's menu. Matched on its title as well, in case the menu item UIKit
  /// builds from the button does not carry its identifier.
  private func packOption(_ kind: String, titled title: String) -> XCUIElement {
    app.descendants(matching: .any)
      .matching(NSPredicate(format: "identifier == %@ OR label == %@", "setDetail.openPack.\(kind)", title))
      .firstMatch
  }
}
