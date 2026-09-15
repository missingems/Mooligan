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
    let tangents: [Double]

    var id: String { kind.rawValue }

    init(kind: PriceSeriesKind, points: [PlotPoint]) {
      self.kind = kind
      self.points = points
      self.tangents = Self.monotoneTangents(points)
    }
  }

  var series: [PriceHistorySection.Series] = []
  var plotSeries: [PlotSeries] = []
  var priceRange: ClosedRange<Double> = 0.0...1.0
  var dateRange: ClosedRange<Date> = Date()...Date()

  var anchorSeries: PriceHistorySection.Series? { series.first }

  /// The most points drawn across every finish together, shared evenly between them. The toolbar
  /// prices still read every day from `series` while scrubbing; only the drawn lines are thinned.
  static let maxPlottedPoints = 180

  var spanInDays: Int { PriceChartStyle.spanInDays(of: dateRange) }

  func series(for kind: PriceSeriesKind) -> PriceHistorySection.Series? {
    series.first { $0.kind == kind }
  }

  init(
    series: [PriceHistorySection.Series] = [],
    priceRange: ClosedRange<Double> = 0.0...1.0,
    dateRange: ClosedRange<Date> = Date()...Date()
  ) {
    self.series = series
    let perSeries = Self.maxPlottedPoints / max(series.count, 1)
    self.plotSeries = series.map { Self.plot($0, limit: perSeries) }
    self.priceRange = priceRange
    self.dateRange = dateRange
  }

  static let windowInDays = 90

  init(section: PriceHistorySection) {
    let windowed = Self.window(section.series, endingAt: section.dateRange.upperBound)

    let series = (windowed.isEmpty ? section.series : windowed)
      .sorted { PriceChartStyle.displayRank($0.kind) < PriceChartStyle.displayRank($1.kind) }

    let low = series.map(\.priceRange.lowerBound).min() ?? 0.0
    let high = series.map(\.priceRange.upperBound).max() ?? 0.0
    let first = series.map(\.dateRange.lowerBound).min() ?? section.dateRange.lowerBound
    let last = series.map(\.dateRange.upperBound).max() ?? section.dateRange.upperBound
    let dates = first...max(last, first.addingTimeInterval(86_400))

    self.init(
      series: series,
      priceRange: low...max(high, low),
      dateRange: dates
    )
  }

  private static func plot(_ series: PriceHistorySection.Series, limit: Int) -> PlotSeries {
    PlotSeries(
      kind: series.kind,
      points: series.points
        .map { PlotPoint(date: $0.date, value: $0.amount.doubleValue) }
        .downsampled(to: limit)
    )
  }

  private static func window(
    _ series: [PriceHistorySection.Series],
    endingAt last: Date
  ) -> [PriceHistorySection.Series] {
    let cutoff = last.addingTimeInterval(-Double(windowInDays) * 86_400)

    return series.compactMap { series in
      let points = series.points.filter { $0.date >= cutoff }
      guard points.count < series.points.count else { return series }
      return PriceHistorySection.Series(kind: series.kind, points: points)
    }
  }
}
