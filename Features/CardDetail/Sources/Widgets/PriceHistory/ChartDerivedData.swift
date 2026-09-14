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

extension ChartDerivedData.PlotSeries {
  func value(at date: Date) -> Double? {
    guard let first = points.first, let last = points.last else { return nil }
    guard date > first.date else { return first.value }
    guard date < last.date else { return last.value }

    var low = 0
    var high = points.count - 1
    while high - low > 1 {
      let mid = (low + high) / 2
      if points[mid].date <= date { low = mid } else { high = mid }
    }

    let x0 = points[low].date.timeIntervalSinceReferenceDate
    let x1 = points[high].date.timeIntervalSinceReferenceDate
    let width = x1 - x0
    guard width > 0.0 else { return points[low].value }

    let u = (date.timeIntervalSinceReferenceDate - x0) / width
    let u2 = u * u
    let u3 = u2 * u
    let y0 = points[low].value
    let y1 = points[high].value

    return (2.0 * u3 - 3.0 * u2 + 1.0) * y0
      + (u3 - 2.0 * u2 + u) * width * tangents[low]
      + (-2.0 * u3 + 3.0 * u2) * y1
      + (u3 - u2) * width * tangents[high]
  }

  fileprivate static func monotoneTangents(_ points: [ChartDerivedData.PlotPoint]) -> [Double] {
    let count = points.count
    guard count > 1 else { return Array(repeating: 0.0, count: count) }

    let xs = points.map(\.date.timeIntervalSinceReferenceDate)
    let ys = points.map(\.value)

    func secant(_ index: Int) -> Double {
      let width = xs[index + 1] - xs[index]
      return width > 0.0 ? (ys[index + 1] - ys[index]) / width : 0.0
    }

    guard count > 2 else {
      let slope = secant(0)
      return [slope, slope]
    }

    var tangents = Array(repeating: 0.0, count: count)
    for index in 1..<(count - 1) {
      let h0 = xs[index] - xs[index - 1]
      let h1 = xs[index + 1] - xs[index]
      let s0 = secant(index - 1)
      let s1 = secant(index)
      let p = h0 + h1 > 0.0 ? (s0 * h1 + s1 * h0) / (h0 + h1) : 0.0
      let sign0: Double = s0 < 0.0 ? -1.0 : 1.0
      let sign1: Double = s1 < 0.0 ? -1.0 : 1.0
      let tangent = (sign0 + sign1) * min(abs(s0), abs(s1), 0.5 * abs(p))
      tangents[index] = tangent.isFinite ? tangent : 0.0
    }

    tangents[0] = (3.0 * secant(0) - tangents[1]) / 2.0
    tangents[count - 1] = (3.0 * secant(count - 2) - tangents[count - 2]) / 2.0
    return tangents
  }
}
