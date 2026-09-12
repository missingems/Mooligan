@testable import CardDetail
import Foundation
import Networking
import Testing

struct PriceHistoryRangeTests {
  private let day: TimeInterval = 86_400
  private let start = Date(timeIntervalSince1970: 1_788_000_000)

  private func decimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
  }

  private func series(
    days count: Int,
    kind: PriceSeriesKind = .normal
  ) -> PriceHistorySection.Series {
    let points = (0..<count).map { offset in
      PricePoint(
        date: start.addingTimeInterval(-Double(count - 1 - offset) * day),
        amount: decimal("\(offset + 1).00")
      )
    }
    return PriceHistorySection.Series(kind: kind, points: points)!
  }

  private func section(
    days count: Int,
    releases: [SetReleaseMarker] = []
  ) -> PriceHistorySection {
    PriceHistorySection(series: [series(days: count)], currency: "USD", releases: releases)
  }

  @Test func whenTheFeedIsShort_shouldOnlyOfferRangesTheDataOutruns() {
    #expect(PriceHistoryRange.available(forSpanOfDays: 11) == [.week, .month])
    #expect(PriceHistoryRange.available(forSpanOfDays: 3) == [.week])
  }

  @Test func whenTheFeedIsLong_shouldOfferEveryRange() {
    #expect(PriceHistoryRange.available(forSpanOfDays: 120) == PriceHistoryRange.allCases)
  }

  @Test func whenARangeIsPicked_shouldStillOfferTheOthers() {
    let feedSpan = 60
    #expect(PriceHistoryRange.available(forSpanOfDays: feedSpan) == [.week, .month, .quarter])

    let drawn = ChartDerivedData(section: section(days: feedSpan), isolatedKind: nil, range: .week)
    #expect(drawn.spanInDays == 7)

    #expect(PriceHistoryRange.available(forSpanOfDays: drawn.spanInDays) == [.week])
  }

  @Test func shouldAlwaysOfferAWayBackToTheWholeFeed() {
    for span in [1, 7, 8, 30, 31, 90, 91, 400] {
      let options = PriceHistoryRange.available(forSpanOfDays: span)
      #expect(options.isEmpty == false, "span \(span) offered nothing")

      let widest = PriceHistoryRange.widest(forSpanOfDays: span)
      #expect(options.last == widest)
      #expect(widest.days >= span || widest == .quarter, "span \(span) cannot reach its whole feed")
    }
  }

  @Test func whenARangeIsPicked_shouldTrimToTheEndOfTheData() {
    let derived = ChartDerivedData(section: section(days: 90), isolatedKind: nil, range: .week)

    let points = derived.displayedSeries[0].points
    #expect(points.count == 8)
    #expect(points.last?.date == start)
    #expect(derived.dateRange.lowerBound == start.addingTimeInterval(-7 * day))
  }

  @Test func whenTheRangeCoversTheFeed_shouldKeepEveryPoint() {
    let derived = ChartDerivedData(section: section(days: 90), isolatedKind: nil, range: .quarter)

    #expect(derived.displayedSeries[0].points.count == 90)
  }

  @Test func whenARangeIsPicked_shouldRescaleToWhatIsLeft() {
    let full = ChartDerivedData(section: section(days: 90), isolatedKind: nil, range: .quarter)
    let week = ChartDerivedData(section: section(days: 90), isolatedKind: nil, range: .week)

    #expect(full.priceRange.lowerBound == 1.0)
    #expect(week.priceRange.lowerBound == 83.0)
    #expect(week.priceRange.upperBound == 90.0)
  }

  @Test func whenARangeIsPicked_shouldDropMarkersOutsideIt() {
    let recent = SetReleaseMarker(
      id: "in", code: "in", name: "Inside",
      date: start.addingTimeInterval(-3 * day), iconURL: nil
    )
    let old = SetReleaseMarker(
      id: "out", code: "out", name: "Outside",
      date: start.addingTimeInterval(-40 * day), iconURL: nil
    )
    let subject = section(days: 90, releases: [old, recent])

    #expect(
      ChartDerivedData(section: subject, isolatedKind: nil, range: .quarter)
        .releases.map(\.id) == ["out", "in"]
    )
    #expect(
      ChartDerivedData(section: subject, isolatedKind: nil, range: .week)
        .releases.map(\.id) == ["in"]
    )
  }

  @Test func whenARangeWouldLeaveNothingDrawable_shouldFallBackToTheFullSeries() {
    let derived = ChartDerivedData(section: section(days: 3), isolatedKind: nil, range: .week)

    #expect(derived.displayedSeries.count == 1)
    #expect(derived.displayedSeries[0].points.count == 3)
  }

  @Test func whenAFinishIsIsolated_shouldWindowOnlyThatFinish() {
    let subject = PriceHistorySection(
      series: [series(days: 90), series(days: 90, kind: .foil)],
      currency: "USD"
    )
    let derived = ChartDerivedData(section: subject, isolatedKind: .foil, range: .week)

    #expect(derived.displayedSeries.map(\.kind) == [.foil])
    #expect(derived.displayedSeries[0].points.count == 8)
  }
}
