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
  var releases: [SetReleaseMarker] = []
  var buylistQuote: BuylistQuote?
  var priceRange: ClosedRange<Double> = 0.0...1.0
  var dateRange: ClosedRange<Date> = Date()...Date()

  var anchorSeries: PriceHistorySection.Series? { series.first }

  var spanInDays: Int { PriceChartStyle.spanInDays(of: dateRange) }

  /// Share of the data's span added before its first date on the chart, so a release icon on the
  /// first day has room to sit centred over its rule instead of against the plot's edge.
  static let leadingDatePadding = 0.05

  /// The x-axis domain: the data's dates with room added before the first one.
  var plotDateRange: ClosedRange<Date> {
    let span = dateRange.upperBound.timeIntervalSince(dateRange.lowerBound)
    return dateRange.lowerBound.addingTimeInterval(-span * Self.leadingDatePadding)...dateRange.upperBound
  }

  func series(for kind: PriceSeriesKind) -> PriceHistorySection.Series? {
    series.first { $0.kind == kind }
  }

  func range(for kind: PriceSeriesKind) -> ClosedRange<Decimal>? {
    guard let series = series(for: kind) else { return nil }
    guard let days = PriceChartStyle.statWindow(forSpanDays: spanInDays).days,
          let last = series.points.last?.date
    else {
      return range(for: series)
    }
    let cutoff = last.addingTimeInterval(-Double(days) * 86_400)
    let amounts = series.points.filter { $0.date >= cutoff }.map(\.amount)
    guard let low = amounts.min(), let high = amounts.max() else { return nil }
    return low...high
  }

  func range(for series: PriceHistorySection.Series) -> ClosedRange<Decimal>? {
    let amounts = series.points.map(\.amount)
    guard let low = amounts.min(), let high = amounts.max() else { return nil }
    return low...high
  }

  func buylist(for kind: PriceSeriesKind) -> Decimal? {
    buylistQuote?.buylist(for: kind)
  }

  func spread(for kind: PriceSeriesKind) -> Double? {
    buylistQuote?.spread(for: kind)
  }

  init(
    series: [PriceHistorySection.Series] = [],
    releases: [SetReleaseMarker] = [],
    buylistQuote: BuylistQuote? = nil,
    priceRange: ClosedRange<Double> = 0.0...1.0,
    dateRange: ClosedRange<Date> = Date()...Date()
  ) {
    self.series = series
    self.plotSeries = series.map(Self.plot)
    self.releases = releases
    self.buylistQuote = buylistQuote
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
      releases: section.releases.filter { dates.contains($0.date) },
      buylistQuote: section.buylistQuote,
      priceRange: low...max(high, low),
      dateRange: dates
    )
  }

  private static func plot(_ series: PriceHistorySection.Series) -> PlotSeries {
    PlotSeries(
      kind: series.kind,
      points: series.points.map { PlotPoint(date: $0.date, value: $0.amount.doubleValue) }
    )
  }

  func isAvailable(_ kind: PriceSeriesKind) -> Bool {
    series.contains { $0.kind == kind }
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
