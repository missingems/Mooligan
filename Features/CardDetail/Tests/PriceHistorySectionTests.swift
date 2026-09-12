@testable import CardDetail
import Foundation
import Networking
import ScryfallKit
import Testing

/// Covers the derivation the reducer now runs off the main actor: joining
/// MTGJSON's history to Scryfall's live quote, and deciding when there is
/// nothing to draw.
struct PriceHistorySectionTests {
  private let today = Date(timeIntervalSince1970: 1_788_000_000)

  private func decimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
  }

  private func point(daysBefore days: Int, _ amount: String) -> PricePoint {
    PricePoint(date: today.addingTimeInterval(-Double(days) * 86_400), amount: decimal(amount))
  }

  /// `Card.mock()` reports `releasedAt` as "1", which is not a day, so a card
  /// built without one exercises the "no release date to trim against" path.
  private func card(
    usd: String? = nil,
    usdFoil: String? = nil,
    releasedAt: String? = nil
  ) -> Card {
    var card = Card.mock()
    card.prices = Card.Prices(usd: usd, usdFoil: usdFoil)
    if let releasedAt { card.releasedAt = releasedAt }
    return card
  }

  /// A release day the way Scryfall spells it, `days` before `today`.
  private func releaseDay(daysBefore days: Int) -> String {
    UTCDay.formatter.string(from: today.addingTimeInterval(-Double(days) * 86_400))
  }

  private func history(_ series: [PriceSeriesKind: [PricePoint]]) -> PriceHistory {
    PriceHistory(
      cardID: "id",
      provider: .tcgplayer,
      listType: .retail,
      currency: "USD",
      series: series
    )
  }

  @Test func whenThereIsNoHistory_shouldBeUnavailable() {
    let state = PriceHistorySection.makeState(
      card: card(),
      history: nil,
      releases: [],
      today: today
    )

    #expect(state == .unavailable)
  }

  /// A single observation cannot be a line, so it is the same as having none.
  @Test func whenAFinishHasOnePoint_shouldBeUnavailable() {
    let state = PriceHistorySection.makeState(
      card: card(),
      history: history([.normal: [point(daysBefore: 1, "1.00")]]),
      releases: [],
      today: today
    )

    #expect(state == .unavailable)
  }

  @Test func whenAFinishHasPoints_shouldProduceASeries() {
    let state = PriceHistorySection.makeState(
      card: card(),
      history: history([
        .normal: [point(daysBefore: 2, "1.00"), point(daysBefore: 1, "1.20")],
      ]),
      releases: [],
      today: today
    )

    guard case let .data(section) = state else {
      Issue.record("expected data, got \(state)")
      return
    }
    #expect(section.series.map(\.kind) == [.normal])
    #expect(section.currency == "USD")
  }

  /// The chart has to end on the number the buy links below it show; MTGJSON
  /// runs a day or two behind Scryfall.
  @Test func whenScryfallHasAQuote_shouldReplaceTheTrailingPoint() {
    let state = PriceHistorySection.makeState(
      card: card(usd: "2.50"),
      history: history([
        .normal: [point(daysBefore: 2, "1.00"), point(daysBefore: 1, "1.20")],
      ]),
      releases: [],
      today: today
    )

    guard case let .data(section) = state else {
      Issue.record("expected data")
      return
    }
    let points = section.series[0].points
    #expect(points.last?.amount == decimal("2.50"))
    #expect(points.last?.date == today)
    #expect(points.count == 3)
  }

  /// A series MTGJSON stopped weeks ago is a printing the feed dropped. Bridging
  /// that gap to today would draw a month of price action nobody observed.
  @Test func whenHistoryIsStale_shouldNotSpliceTheLiveQuote() {
    let state = PriceHistorySection.makeState(
      card: card(usd: "2.50"),
      history: history([
        .normal: [point(daysBefore: 40, "1.00"), point(daysBefore: 39, "1.20")],
      ]),
      releases: [],
      today: today
    )

    guard case let .data(section) = state else {
      Issue.record("expected data")
      return
    }
    #expect(section.series[0].points.count == 2)
    #expect(section.series[0].points.last?.amount == decimal("1.20"))
  }

  /// Scryfall reports "0.00" for cards nobody stocks rather than omitting it.
  @Test func whenScryfallQuotesZero_shouldBeIgnored() {
    #expect(PriceHistorySection.scryfallQuote(card: card(usd: "0.00"), kind: .normal) == nil)
    #expect(PriceHistorySection.scryfallQuote(card: card(), kind: .normal) == nil)
    #expect(PriceHistorySection.scryfallQuote(card: card(usd: "1.25"), kind: .normal) == decimal("1.25"))
  }

  @Test func whenBothFinishesHaveHistory_shouldOrderRegularBeforeFoil() {
    let state = PriceHistorySection.makeState(
      card: card(),
      history: history([
        .foil: [point(daysBefore: 2, "5.00"), point(daysBefore: 1, "5.50")],
        .normal: [point(daysBefore: 2, "1.00"), point(daysBefore: 1, "1.20")],
      ]),
      releases: [],
      today: today
    )

    guard case let .data(section) = state else {
      Issue.record("expected data")
      return
    }
    #expect(section.series.map(\.kind) == [.normal, .foil])
  }

  /// Markers outside what the chart actually plots would sit on an axis position
  /// that does not exist.
  @Test func whenAReleaseFallsOutsideTheSeries_shouldBeDropped() {
    let inside = SetReleaseMarker(
      id: "in", code: "in", name: "Inside",
      date: today.addingTimeInterval(-1.5 * 86_400), iconURL: nil
    )
    let outside = SetReleaseMarker(
      id: "out", code: "out", name: "Outside",
      date: today.addingTimeInterval(-200 * 86_400), iconURL: nil
    )

    let state = PriceHistorySection.makeState(
      card: card(),
      history: history([
        .normal: [point(daysBefore: 2, "1.00"), point(daysBefore: 1, "1.20")],
      ]),
      releases: [inside, outside],
      today: today
    )

    guard case let .data(section) = state else {
      Issue.record("expected data")
      return
    }
    #expect(section.releases.map(\.id) == ["in"])
  }

  /// TCGplayer lists a card weeks before it is legal to sell, so MTGJSON's feed
  /// opens with preorder quotes. Those are speculation on an unopened product,
  /// and they are usually the highest numbers in the series — leaving them in
  /// drags the y scale up and makes every card look like it crashed on release.
  @Test func whenHistoryPredatesTheRelease_shouldStartAtTheReleaseDay() {
    let state = PriceHistorySection.makeState(
      card: card(releasedAt: releaseDay(daysBefore: 3)),
      history: history([
        .normal: [
          point(daysBefore: 6, "9.00"),
          point(daysBefore: 5, "8.00"),
          point(daysBefore: 3, "4.00"),
          point(daysBefore: 2, "4.20"),
          point(daysBefore: 1, "4.10"),
        ],
      ]),
      releases: [],
      today: today
    )

    guard case let .data(section) = state else {
      Issue.record("expected data, got \(state)")
      return
    }
    let points = section.series[0].points
    #expect(points.count == 3)
    #expect(points.first?.amount == decimal("4.00"))
    // The preorder run no longer drives the y scale.
    #expect(section.priceRange.upperBound < 5.0)
  }

  /// Nothing to trim against, so nothing is trimmed — a printing whose release
  /// date we cannot read should still draw everything the feed has.
  @Test func whenTheReleaseDateIsUnreadable_shouldKeepEveryPoint() {
    let state = PriceHistorySection.makeState(
      card: card(),
      history: history([
        .normal: [point(daysBefore: 40, "1.00"), point(daysBefore: 1, "1.20")],
      ]),
      releases: [],
      today: today
    )

    guard case let .data(section) = state else {
      Issue.record("expected data")
      return
    }
    #expect(section.series[0].points.count == 2)
  }

  /// A printing released today has no post-release market yet. Saying so beats
  /// charting a week of preorder speculation as if it were price action.
  @Test func whenEveryQuotePredatesTheRelease_shouldBeUnavailable() {
    let state = PriceHistorySection.makeState(
      card: card(releasedAt: releaseDay(daysBefore: 0)),
      history: history([
        .normal: [point(daysBefore: 6, "9.00"), point(daysBefore: 5, "8.00")],
      ]),
      releases: [],
      today: today
    )

    #expect(state == .unavailable)
  }

  /// The live quote is spliced onto what survives the trim, so a card released
  /// two days ago still draws a line instead of falling back to unavailable.
  @Test func whenOnlyOneQuoteSurvivesTheTrim_shouldStillJoinTheLiveQuote() {
    let state = PriceHistorySection.makeState(
      card: card(usd: "5.00", releasedAt: releaseDay(daysBefore: 2)),
      history: history([
        .normal: [
          point(daysBefore: 6, "9.00"),
          point(daysBefore: 2, "4.00"),
        ],
      ]),
      releases: [],
      today: today
    )

    guard case let .data(section) = state else {
      Issue.record("expected data")
      return
    }
    let points = section.series[0].points
    #expect(points.map(\.amount) == [decimal("4.00"), decimal("5.00")])
    #expect(points.last?.date == today)
  }
}
