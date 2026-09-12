import Charts
import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

/// Price history for the card currently on screen.
struct PriceHistoryChartView: View {
  struct Quote: Identifiable, Equatable {
    let label: String
    let amount: Decimal
    
    var id: String { label }
  }
  
  private let state: PriceHistoryState
  private let quotes: [Quote]
  private let title: String
  private let sourceLabel: String
  private let unavailableLabel: String
  private let legendRows: Int
  
  @Environment(\.colorScheme) private var colorScheme
  @State private var isolatedKind: PriceSeriesKind?
  @State private var derivedData = ChartDerivedData()
  @State private var plot: CGRect = .zero
  @State private var interaction = ChartInteraction()
  
  init(
    state: PriceHistoryState,
    quotes: [Quote] = [],
    title: String,
    sourceLabel: String,
    unavailableLabel: String,
    legendRows: Int
  ) {
    self.state = state
    self.quotes = quotes
    self.title = title
    self.sourceLabel = sourceLabel
    self.unavailableLabel = unavailableLabel
    self.legendRows = legendRows
  }
  
  var body: some View {
    VibrantDivider()
      .safeAreaPadding(.leading, systemHorizontalMargin)
    
    VStack(alignment: .leading, spacing: 5.0) {
      Text(title)
        .font(.headline)
      
      if case let .data(section) = state {
        DynamicSpanTextView(section: section, derivedData: derivedData, interaction: interaction)
      }
      
      chart(for: state.data)
        .id(colorScheme)
        .frame(height: 233, alignment: .leading)
        .onAppear {
          updateDerivedData(for: state.data)
        }
        .onChange(of: isolatedKind) {
          updateDerivedData(for: state.data)
        }
    }
    .padding(.horizontal, systemHorizontalMargin)
    .padding(.vertical, 13.0)
  }
  
  private var currencyCode: String {
    if case let .data(section) = state { return section.currency } else { return "USD" }
  }
  
  private func updateDerivedData(for section: PriceHistorySection) {
    let displayed = isolatedKind == nil ? section.series : section.series.filter { $0.kind == isolatedKind }
    
    let priceExtents: ClosedRange<Double>
    let dateExtents: ClosedRange<Date>
    
    if let isolatedKind, let only = section.series.first(where: { $0.kind == isolatedKind }) {
      priceExtents = only.priceRange
      dateExtents = only.dateRange
    } else {
      priceExtents = section.priceRange
      dateExtents = section.dateRange
    }
    
    derivedData = ChartDerivedData(
      displayedSeries: displayed,
      priceRange: priceExtents,
      dateRange: dateExtents
    )
  }
}

// MARK: - Chart

private extension PriceHistoryChartView {
  func chart(for section: PriceHistorySection) -> some View {
    let domain = yDomain(for: derivedData.priceRange)
    let fractionDigits = derivedData.priceRange.upperBound < 10 ? 2 : 0
    
    return Chart {
      ForEach(derivedData.displayedSeries) { series in
        // Extract the label once per series
        let seriesLabel = chartLabel(for: series.kind)
        
        ForEach(series.points) { point in
          LineMark(
            x: .value("Date", point.date),
            y: .value("Price", point.amount.doubleValue),
            series: .value("ID", series.id) // 1. Restored explicit series grouping
          )
          .interpolationMethod(.monotone)
          .foregroundStyle(by: .value("Finish", seriesLabel))
          
          if derivedData.displayedSeries.count == 1 {
            AreaMark(
              x: .value("Date", point.date),
              yStart: .value("Floor", domain.lowerBound),
              yEnd: .value("Price", point.amount.doubleValue),
              series: .value("ID", series.id)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(
              .linearGradient(
                colors: [
                  chartColor(for: series.kind).opacity(0.26),
                  chartColor(for: series.kind).opacity(0.0),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
          }
        }
      }
    }
    // 3. Safer domain/range array mapping instead of dictionary
    .chartForegroundStyleScale(
      domain: [chartLabel(for: .normal), chartLabel(for: .foil), chartLabel(for: .etched)],
      range: [chartColor(for: .normal), chartColor(for: .foil), chartColor(for: .etched)]
    )
    .chartLegend(position: .bottom, alignment: .leading, spacing: 16)
    .chartYScale(domain: domain)
    .chartXScale(domain: derivedData.dateRange)
    .chartYAxis {
      AxisMarks(position: .trailing, values: .automatic) { value in
        AxisGridLine().foregroundStyle(
          (colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225))
            .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
        )
        
        AxisValueLabel(anchor: .leading) {
          if let amount = value.as(Double.self) {
            Text(amount, format: .number.precision(.fractionLength(fractionDigits)))
              .font(.caption2)
          }
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic(desiredCount: 3)) { value in
        AxisGridLine().foregroundStyle(
          (colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225))
            .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
        )
        
        AxisValueLabel(
          format: axisDateStyle(forDays: spanInDays(of: derivedData.dateRange)),
          anchor: .top
        )
      }
    }
  }
  
  func yDomain(for prices: ClosedRange<Double>) -> ClosedRange<Double> {
    let low = prices.lowerBound
    let high = prices.upperBound
    guard low.isFinite, high.isFinite else { return 0.0...1.0 }
    
    let span = high - low
    let padding = span > 0 ? span * 0.12 : max(abs(high) * 0.1, 0.05)
    let lower = max(0.0, low - padding)
    let upper = high + padding * 2.5
    guard lower.isFinite, upper.isFinite, upper > lower else { return 0.0...1.0 }
    return lower...upper
  }
}

// MARK: - Observation Models

struct ChartDerivedData: Equatable {
  var displayedSeries: [PriceHistorySection.Series] = []
  var priceRange: ClosedRange<Double> = 0.0...1.0
  var dateRange: ClosedRange<Date> = Date()...Date()
}

@Observable
final class ChartInteraction {
  var scrubbedDate: Date?
  
  /// Caches the indices of the last scrub lookup to skip the binary search
  /// when the finger drags continuously across contiguous days.
  /// Not observed, so internal mutations don't risk SwiftUI update cycles.
  @ObservationIgnored
  private var lastFoundIndices: [String: Int] = [:]
  
  func nearestPoint(in series: PriceHistorySection.Series, to date: Date) -> PricePoint? {
    let points = series.points
    guard points.isEmpty == false else { return nil }
    
    // O(1) Fast Path: Temporal Locality
    if let lastIdx = lastFoundIndices[series.id], points.indices.contains(lastIdx) {
      let candidate = points[lastIdx]
      // If we are within one day of the last cached query, check neighbors directly
      if abs(candidate.date.timeIntervalSince(date)) < 86_400 {
        var bestIdx = lastIdx
        var minDiff = abs(candidate.date.timeIntervalSince(date))
        
        if lastIdx > 0 {
          let prevDiff = abs(points[lastIdx - 1].date.timeIntervalSince(date))
          if prevDiff < minDiff {
            bestIdx = lastIdx - 1
            minDiff = prevDiff
          }
        }
        if lastIdx < points.count - 1 {
          let nextDiff = abs(points[lastIdx + 1].date.timeIntervalSince(date))
          if nextDiff < minDiff {
            bestIdx = lastIdx + 1
          }
        }
        
        lastFoundIndices[series.id] = bestIdx
        return points[bestIdx]
      }
    }
    
    // O(log N) Fallback: Binary Search
    var low = 0
    var high = points.count - 1
    while low < high {
      let mid = (low + high) / 2
      if points[mid].date < date { low = mid + 1 } else { high = mid }
    }
    
    let candidate = points[low]
    var bestIdx = low
    
    if low > 0 {
      let previous = points[low - 1]
      if abs(previous.date.timeIntervalSince(date)) <= abs(candidate.date.timeIntervalSince(date)) {
        bestIdx = low - 1
      }
    }
    
    lastFoundIndices[series.id] = bestIdx
    return points[bestIdx]
  }
  
  func readout(for series: PriceHistorySection.Series) -> (point: PricePoint, change: PriceChange?)? {
    guard let last = series.points.last else { return nil }
    
    if let scrubbedDate = scrubbedDate, let point = nearestPoint(in: series, to: scrubbedDate) {
      guard let first = series.points.first, first.date != point.date else {
        return (point, nil)
      }
      return (point, PriceChange(start: first, end: point))
    }
    return (last, series.points.change)
  }
}

// MARK: - Performance Subviews

/// A tiny view bound to the interaction state. Redraws only this text on scrub.
private struct DynamicSpanTextView: View {
  let section: PriceHistorySection
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  
  var body: some View {
    Text(spanText)
      .font(.caption)
      .foregroundStyle(.secondary)
      .contentTransition(.numericText())
  }
  
  private var spanText: String {
    if let scrubbedDate = interaction.scrubbedDate,
       let anchor = derivedData.displayedSeries.first,
       let point = interaction.nearestPoint(in: anchor, to: scrubbedDate) {
      return point.date.formatted(date: .abbreviated, time: .omitted)
    }
    
    let days = spanInDays(of: derivedData.dateRange)
    switch days {
    case ..<14: return String(localized: "Past \(days) Days")
    case ..<60:
      let weeks = max(1, Int((Double(days) / 7.0).rounded()))
      return String(localized: "Past \(weeks) Weeks")
    default:
      let months = max(1, Int((Double(days) / 30.0).rounded()))
      return String(localized: "Past \(months) Months")
    }
  }
}

/// Houses the release symbols and scrub indicator, ensuring `ChartTouchReader` updates
/// never reach the parent view hierarchy.
private struct DynamicChartOverlayView: View {
  let section: PriceHistorySection
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  let proxy: ChartProxy
  let plot: CGRect
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      // 1. Focus Indicator Overlay
      if let focusDate = interaction.scrubbedDate,
         let focusX = proxy.position(forX: focusDate), focusX.isFinite {
        
        Rectangle()
          .fill(.secondary.opacity(0.45))
          .frame(width: 1.0, height: plot.height)
          .position(x: plot.minX + focusX, y: plot.midY)
          .allowsHitTesting(false)
        
        ForEach(derivedData.displayedSeries) { series in
          if let point = interaction.nearestPoint(in: series, to: focusDate),
             let x = proxy.position(forX: point.date),
             let y = proxy.position(forY: point.amount.doubleValue),
             x.isFinite, y.isFinite {
            
            Circle()
              .fill(chartColor(for: series.kind))
              .frame(width: 8.44, height: 8.44)
              .position(x: plot.minX + x, y: plot.minY + y)
              .allowsHitTesting(false)
          }
        }
      }
      
      // 2. Release Symbol Overlay
      let positions = releasePositions(section.releases)
      let focused = focusedReleaseID(among: positions)
      
      ForEach(positions, id: \.release.id) { entry in
        releaseIcon(entry.release, expanded: entry.release.id == focused)
          .position(x: entry.x, y: plot.minY + releaseBandHeight / 2.0)
          .zIndex(entry.release.id == focused ? 1.0 : 0.0)
          .allowsHitTesting(false)
      }
      .animation(.snappy(duration: 0.18), value: focused)
      
      // 3. Touch Reader
      ChartTouchReader { positions in
        updateInteraction(positions)
      }
    }
  }
  
  private func releasePositions(_ releases: [SetReleaseMarker]) -> [(release: SetReleaseMarker, x: CGFloat)] {
    releases.compactMap { release in
      guard let x = proxy.position(forX: release.date), x.isFinite else { return nil }
      return (release, min(max(plot.minX + x, plot.minX + 16.0), plot.maxX - 16.0))
    }
  }
  
  private func focusedReleaseID(among positions: [(release: SetReleaseMarker, x: CGFloat)]) -> String? {
    guard let focusDate = interaction.scrubbedDate,
          let focusX = proxy.position(forX: focusDate),
          focusX.isFinite else { return nil }
    
    let absoluteX = plot.minX + focusX
    guard let nearest = positions.min(by: { abs($0.x - absoluteX) < abs($1.x - absoluteX) }) else { return nil }
    return abs(nearest.x - absoluteX) <= 22.0 ? nearest.release.id : nil
  }
  
  private func releaseIcon(_ release: SetReleaseMarker, expanded: Bool) -> some View {
    IconLazyImage(release.iconURL, tintColor: expanded ? .primary : .secondary)
      .frame(width: expanded ? 24.0 : 18.0, height: expanded ? 24.0 : 18.0)
      .padding(expanded ? 5.0 : 4.0)
      .background(.background.opacity(0.9), in: Circle())
      .overlay(Circle().strokeBorder(.separator, lineWidth: expanded ? 1.0 : 0.0))
      .overlay(alignment: .top) {
        Text(release.name)
          .font(.caption2)
          .fontWeight(.medium)
          .lineLimit(1)
          .fixedSize()
          .padding(.horizontal, 6.0)
          .padding(.vertical, 2.0)
          .background(.background.opacity(0.92), in: Capsule())
          .overlay(Capsule().strokeBorder(.separator, lineWidth: 0.5))
          .offset(y: expanded ? 38.0 : 30.0)
          .opacity(expanded ? 1.0 : 0.0)
          .allowsHitTesting(false)
      }
      .accessibilityLabel(Text(release.name))
  }
  
  private func updateInteraction(_ positions: [CGFloat]) {
    guard plot.width > 0 else { return }
    guard let x = positions.first else {
      if interaction.scrubbedDate != nil { interaction.scrubbedDate = nil }
      return
    }
    
    let clamped = min(max(x - plot.minX, 0.0), plot.width)
    guard let date = proxy.value(atX: clamped, as: Date.self) else { return }
    interaction.scrubbedDate = date
  }
}

// MARK: - Shared UI Styling / Helpers

fileprivate let releaseBandHeight: CGFloat = 38.0

fileprivate func trendColor(_ change: PriceChange?) -> Color {
  guard let change, change.isIncrease || change.isDecrease else { return .secondary }
  return change.isIncrease ? .green : .red
}

fileprivate func chartColor(for kind: PriceSeriesKind) -> Color {
  switch kind {
  case .normal: return DesignComponentsAsset.accentColor.swiftUIColor
  case .foil: return .orange
  case .etched: return .purple
  }
}

fileprivate func chartLabel(for kind: PriceSeriesKind) -> String {
  switch kind {
  case .normal: return String(localized: "Regular")
  case .foil: return String(localized: "Foil")
  case .etched: return String(localized: "Etched Foil")
  }
}

fileprivate func changeText(for change: PriceChange, currencyCode: String) -> String {
  let sign = change.isIncrease ? "+" : ""
  let formatted = change.absolute.formatted(.currency(code: currencyCode))
  guard let fraction = change.fraction else { return sign + formatted }
  return "\(sign)\(formatted) (\(fraction.formatted(.percent.precision(.fractionLength(0...1)))))"
}

fileprivate func spanInDays(of dates: ClosedRange<Date>) -> Int {
  max(1, Int((dates.upperBound.timeIntervalSince(dates.lowerBound) / 86_400).rounded()))
}

fileprivate func axisDateStyle(forDays days: Int) -> Date.FormatStyle {
  switch days {
  case ..<10: return .dateTime.weekday(.abbreviated)
  case ..<60: return .dateTime.month(.abbreviated).day()
  default: return .dateTime.month(.abbreviated)
  }
}

private extension Decimal {
  var doubleValue: Double { (self as NSDecimalNumber).doubleValue }
}
