import Foundation
import Networking

struct ChartDerivedData: Equatable, Sendable {
  struct PlotPoint: Identifiable, Equatable, Sendable {
    let date: Date
    let value: Double

    var id: Date { date }
  }

  struct PlotSeries: Identifiable, Equatable, Sendable {
    let kind: PriceSeriesKind
    let points: [PlotPoint]

    var id: String { kind.rawValue }
  }

  var displayedSeries: [PriceHistorySection.Series] = []
  var plotSeries: [PlotSeries] = []
  var releases: [SetReleaseMarker] = []
  var priceRange: ClosedRange<Double> = 0.0...1.0
  var dateRange: ClosedRange<Date> = Date()...Date()

  var anchorSeries: PriceHistorySection.Series? { displayedSeries.first }

  var spanInDays: Int { PriceChartStyle.spanInDays(of: dateRange) }

  init(
    displayedSeries: [PriceHistorySection.Series] = [],
    releases: [SetReleaseMarker] = [],
    priceRange: ClosedRange<Double> = 0.0...1.0,
    dateRange: ClosedRange<Date> = Date()...Date()
  ) {
    self.displayedSeries = displayedSeries
    self.plotSeries = displayedSeries.map { series in
      PlotSeries(
        kind: series.kind,
        points: series.points.map { PlotPoint(date: $0.date, value: $0.amount.doubleValue) }
      )
    }
    self.releases = releases
    self.priceRange = priceRange
    self.dateRange = dateRange
  }

  init(
    section: PriceHistorySection,
    isolatedKind: PriceSeriesKind?,
    range: PriceHistoryRange
  ) {
    let candidates = isolatedKind.map { kind in
      section.series.filter { $0.kind == kind }
    } ?? section.series

    let windowed = Self.window(candidates, to: range, endingAt: section.dateRange.upperBound)

    let series = (windowed.isEmpty ? candidates : windowed)
      .sorted { PriceChartStyle.displayRank($0.kind) < PriceChartStyle.displayRank($1.kind) }

    let low = series.map(\.priceRange.lowerBound).min() ?? 0.0
    let high = series.map(\.priceRange.upperBound).max() ?? 0.0
    let first = series.map(\.dateRange.lowerBound).min() ?? section.dateRange.lowerBound
    let last = series.map(\.dateRange.upperBound).max() ?? section.dateRange.upperBound
    let dates = first...max(last, first.addingTimeInterval(86_400))

    self.init(
      displayedSeries: series,
      releases: section.releases.filter { dates.contains($0.date) },
      priceRange: low...max(high, low),
      dateRange: dates
    )
  }

  private static func window(
    _ series: [PriceHistorySection.Series],
    to range: PriceHistoryRange,
    endingAt last: Date
  ) -> [PriceHistorySection.Series] {
    let cutoff = range.cutoff(endingAt: last)

    return series.compactMap { series in
      let points = series.points.filter { $0.date >= cutoff }
      guard points.count < series.points.count else { return series }
      return PriceHistorySection.Series(kind: series.kind, points: points)
    }
  }
}
