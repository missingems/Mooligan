@testable import Networking
import ScryfallKit
import Testing

struct SearchQueryCacheKeyTests {
  private func query() -> SearchQuery {
    SearchQuery(setCode: "fdn", page: 1, sortMode: .name, sortDirection: .asc)
  }

  @Test func whenOnlyThePageDiffers_shouldShareAKey() {
    var first = query()
    var second = query()
    second.page = 7

    #expect(first.cacheKey == second.cacheKey)
    first.page = 3
    #expect(first.cacheKey == second.cacheKey)
  }

  @Test func whenTheNameFilterDiffers_shouldNotShareAKey() {
    var other = query()
    other.name = "bolt"

    #expect(query().cacheKey != other.cacheKey)
  }

  @Test func whenTheSortDiffers_shouldNotShareAKey() {
    var byPrice = query()
    byPrice.sortMode = .usd
    var descending = query()
    descending.sortDirection = .desc

    #expect(query().cacheKey != byPrice.cacheKey)
    #expect(query().cacheKey != descending.cacheKey)
  }

  @Test func whenTheSetDiffers_shouldNotShareAKey() {
    var other = query()
    other.setCode = "mkm"

    #expect(query().cacheKey != other.cacheKey)
  }

  @Test func whenUnorderedFiltersAreEqual_shouldShareAKey() {
    var first = query()
    var second = query()
    first.colorIdentities = [.R, .G, .W]
    second.colorIdentities = [.W, .G, .R]

    #expect(first.cacheKey == second.cacheKey)
  }

  @Test func whenColourFiltersDiffer_shouldNotShareAKey() {
    var first = query()
    var second = query()
    first.colorIdentities = [.R]
    second.colorIdentities = [.U]

    #expect(first.cacheKey != second.cacheKey)
  }

  @Test func whenCardTypesDiffer_shouldNotShareAKey() {
    var other = query()
    other.cardType = [.creature]

    #expect(query().cacheKey != other.cacheKey)
  }

  @Test func whenBrowsingAWholeSet_shouldBeEligibleForTheLocalCatalog() {
    #expect(query().isUnfilteredSetBrowse)
  }

  @Test func whenThereIsNoSet_shouldNotBeEligible() {
    var other = query()
    other.setCode = nil

    #expect(other.isUnfilteredSetBrowse == false)
  }

  @Test func whenAnyFilterIsApplied_shouldNotBeEligible() {
    var named = query()
    named.name = "bolt"
    var typed = query()
    typed.cardType = [.creature]
    var coloured = query()
    coloured.colorIdentities = [.R]
    var numbered = query()
    numbered.collectorNumber = "12"

    #expect(named.isUnfilteredSetBrowse == false)
    #expect(typed.isUnfilteredSetBrowse == false)
    #expect(coloured.isUnfilteredSetBrowse == false)
    #expect(numbered.isUnfilteredSetBrowse == false)
  }

  @Test func whenTheTypeFilterIsAll_shouldStillBeEligible() {
    var other = query()
    other.cardType = [.all]

    #expect(other.isUnfilteredSetBrowse)
  }
}
