@testable import CardDetail
import Foundation
import Networking
import Testing

struct ChartDerivedDataTests {
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

  private func section(days count: Int) -> PriceHistorySection {
    PriceHistorySection(series: [series(days: count)], currency: "USD")
  }

  @Test func shouldTrimToTheFixedWindowEndingAtTheLastObservation() {
    let derived = ChartDerivedData(section: section(days: 200))
    let points = derived.series[0].points

    #expect(points.count == ChartDerivedData.windowInDays + 1)
    #expect(points.last?.date == start)
    #expect(derived.dateRange.lowerBound == start.addingTimeInterval(-90 * day))
  }

  @Test func theWindowShouldSpanItsFixedNumberOfDays() {
    let derived = ChartDerivedData(section: section(days: 200))

    #expect(derived.spanInDays == ChartDerivedData.windowInDays)
  }

  @Test func whenTheFeedIsShorterThanTheWindow_shouldKeepEveryPoint() {
    let derived = ChartDerivedData(section: section(days: 40))

    #expect(derived.series[0].points.count == 40)
  }

  @Test func shouldRescaleToWhatSurvivesTheWindow() {
    let derived = ChartDerivedData(section: section(days: 200))

    #expect(derived.priceRange.lowerBound == 110.0)
    #expect(derived.priceRange.upperBound == 200.0)
  }

  @Test func shouldReportWhichFinishesTheCardHas() {
    let subject = PriceHistorySection(
      series: [series(days: 200), series(days: 200, kind: .foil)],
      currency: "USD"
    )
    let derived = ChartDerivedData(section: subject)

    #expect(derived.series.map(\.kind) == [.normal, .foil])
    #expect(derived.series(for: .foil)?.kind == .foil)
    #expect(derived.series(for: .etched) == nil)
  }

  @Test func shouldPrecomputePlotValues() {
    let derived = ChartDerivedData(section: section(days: 40))

    #expect(derived.plotSeries.map(\.kind) == derived.series.map(\.kind))
    #expect(derived.plotSeries[0].points.count == derived.series[0].points.count)
    #expect(derived.plotSeries[0].points.last?.value == 40.0)
  }

  @Test func theEmptySectionShouldBeStableAndSpanTheWindow() {
    #expect(PriceHistoryState.loading.data.dateRange == PriceHistoryState.unavailable.data.dateRange)

    let span = PriceChartStyle.spanInDays(of: PriceHistoryState.loading.data.dateRange)
    #expect(span == ChartDerivedData.windowInDays)
  }

  @Test func theDotShouldPassThroughEveryObservation() {
    let derived = ChartDerivedData(section: section(days: 10))
    let plot = derived.plotSeries[0]

    for point in plot.points {
      #expect(abs((plot.value(at: point.date) ?? .nan) - point.value) < 0.000_1)
    }
  }

  @Test func betweenObservations_theDotShouldGlideAlongTheCurve() {
    let derived = ChartDerivedData(section: section(days: 10))
    let plot = derived.plotSeries[0]
    let midway = plot.points[4].date.addingTimeInterval(day / 2.0)

    #expect(abs((plot.value(at: midway) ?? .nan) - 5.5) < 0.000_1)
  }

  @Test func theDotShouldNotOvershootAFlatStep() {
    let points = [1.0, 1.0, 5.0, 5.0].enumerated().map { offset, value in
      ChartDerivedData.PlotPoint(date: start.addingTimeInterval(Double(offset) * day), value: value)
    }
    let plot = ChartDerivedData.PlotSeries(kind: .normal, points: points)

    for step in 0...30 {
      let value = plot.value(at: start.addingTimeInterval(Double(step) / 10.0 * day)) ?? .nan
      #expect(value >= 1.0 - 0.000_1 && value <= 5.0 + 0.000_1)
    }
  }

  @Test func outsideTheSeries_theDotShouldHoldTheEndpoint() {
    let derived = ChartDerivedData(section: section(days: 10))
    let plot = derived.plotSeries[0]

    #expect(plot.value(at: .distantPast) == plot.points.first?.value)
    #expect(plot.value(at: .distantFuture) == plot.points.last?.value)
  }

  @Test func anchorSeries_shouldBeTheFirstFinishDrawn() {
    let subject = PriceHistorySection(
      series: [series(days: 10), series(days: 10, kind: .foil)],
      currency: "USD"
    )

    #expect(ChartDerivedData(section: subject).anchorSeries?.kind == .normal)
  }

  @Test func series_shouldBeOrderedRegularFoilEtched() {
    let subject = PriceHistorySection(
      series: [series(days: 10, kind: .etched), series(days: 10, kind: .foil), series(days: 10)],
      currency: "USD"
    )

    #expect(ChartDerivedData(section: subject).series.map(\.kind) == [.normal, .foil, .etched])
  }
}
