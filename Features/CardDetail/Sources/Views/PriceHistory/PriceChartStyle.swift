import DesignComponents
import Foundation
import Networking
import SwiftUI

enum PriceChartStyle {
  static let swatchSize: CGFloat = 5.0

  static func color(for kind: PriceSeriesKind) -> Color {
    switch kind {
    case .normal: DesignComponentsAsset.accentColor.swiftUIColor
    case .foil: .orange
    case .etched: .purple
    }
  }

  static let displayOrder: [PriceSeriesKind] = [.normal, .foil, .etched]

  static func displayRank(_ kind: PriceSeriesKind) -> Int {
    displayOrder.firstIndex(of: kind) ?? displayOrder.count
  }

  static func label(for kind: PriceSeriesKind) -> String {
    switch kind {
    case .normal: String(localized: "Regular")
    case .foil: String(localized: "Foil")
    case .etched: String(localized: "Etched")
    }
  }

  /// Holds the place of a value that is loading or missing.
  static let missingValue = "—"

  static func price(_ code: String) -> Decimal.FormatStyle.Currency {
    .currency(code: code)
      .presentation(.narrow)
      .precision(.fractionLength(2))
  }

  static func ratioText(_ ratio: Double) -> String {
    ratio.formatted(.percent.precision(.fractionLength(0)))
  }

  /// The lowest and highest ratio as a range, or one figure when they read the same.
  static func ratioRangeText(_ ratios: [Double]) -> String? {
    guard let low = ratios.min(), let high = ratios.max() else { return nil }
    let lowText = ratioText(low)
    let highText = ratioText(high)
    return lowText == highText ? lowText : "\(lowText)–\(highText)"
  }

  /// Axis labels keep two decimals like every other price, whole-dollar ticks included.
  static func axisPrice(_ code: String) -> FloatingPointFormatStyle<Double>.Currency {
    .currency(code: code)
      .presentation(.narrow)
      .precision(.fractionLength(2))
  }

  static func vibrantBlendMode(_ colorScheme: ColorScheme) -> BlendMode {
    colorScheme == .dark ? .plusLighter : .plusDarker
  }

  static func gridTint(_ colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225)
  }

  /// For Swift Charts marks, which take a shape style rather than a view, so there is no view to
  /// put in a compositing group before the blend.
  static func gridColor(_ colorScheme: ColorScheme) -> some ShapeStyle {
    gridTint(colorScheme).blendMode(vibrantBlendMode(colorScheme))
  }

  static let needleWidth: CGFloat = 1.0

  /// Round dots a point across, three points apart.
  static let gridStroke = StrokeStyle(lineWidth: 1.0, lineCap: .round, dash: [0.0, 3.0])

  static func vibrantLabelTint(_ colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.45) : Color.black.opacity(0.5)
  }

  struct PriceAxis: Equatable, Sendable {
    let domain: ClosedRange<Double>
    let ticks: [Double]
    var tickLabels: [String] = []

    func labeled(currencyCode: String) -> PriceAxis {
      var axis = self
      axis.tickLabels = ticks.map { $0.formatted(PriceChartStyle.axisPrice(currencyCode)) }
      return axis
    }

    func label(at index: Int) -> String {
      tickLabels.indices.contains(index) ? tickLabels[index] : ""
    }
  }

  static let fallbackPriceAxis = PriceAxis(domain: 0.0...1.0, ticks: [0.0, 0.5, 1.0])

  /// How far either side of the known prices an estimated axis reaches, so a typical three months of
  /// movement already falls inside it.
  static let estimatedAxisPadding = 0.15

  /// An axis for before there is any price history, built around the prices already known from
  /// Scryfall so it reads close to the axis the loaded chart will have.
  static func estimatedPriceAxis(around prices: [Double]) -> PriceAxis {
    guard let low = prices.min(), let high = prices.max() else { return fallbackPriceAxis }
    return priceAxis(for: (low * (1.0 - estimatedAxisPadding))...(high * (1.0 + estimatedAxisPadding)))
  }

  static func priceAxis(for prices: ClosedRange<Double>, intervals: Double = 3.0) -> PriceAxis {
    let low = max(prices.lowerBound, 0.0)
    let high = prices.upperBound
    guard low.isFinite, high.isFinite, high >= low, high > 0.0 else { return fallbackPriceAxis }

    let span = max(high - low, high * 0.1, 0.01)
    let step = niceStep(span / intervals)

    var lower = (low / step).rounded(.down) * step
    if low - lower < step * 0.5 { lower -= step }
    lower = max(lower, 0.0)

    var upper = (high / step).rounded(.up) * step
    if upper - high < step * 0.5 { upper += step }

    // Ticks are whole steps and the domain runs from the first to the last of them exactly. Rounding
    // `lower` and `upper` separately could leave the top tick a hair above the domain (0.6000000000000001
    // against 0.6), which Swift Charts treats as out of range and leaves without its label.
    let first = Int((lower / step).rounded())
    let last = max(Int((upper / step).rounded()), first + 1)
    let ticks = (first...last).map { Double($0) * step }
    return PriceAxis(domain: ticks[0]...ticks[ticks.count - 1], ticks: ticks)
  }

  static func niceStep(_ raw: Double) -> Double {
    guard raw.isFinite, raw > 0.0 else { return 1.0 }
    let magnitude = pow(10.0, (log10(raw)).rounded(.down))
    let fraction = raw / magnitude
    let nice: Double = switch fraction {
    case ...1.0: 1.0
    case ...2.0: 2.0
    case ...2.5: 2.5
    case ...5.0: 5.0
    default: 10.0
    }
    return nice * magnitude
  }

  static func spanInDays(of dates: ClosedRange<Date>) -> Int {
    max(1, Int((dates.upperBound.timeIntervalSince(dates.lowerBound) / 86_400).rounded()))
  }

  static func axisDateStyle(forDays days: Int) -> Date.FormatStyle {
    switch days {
    case ..<10: .dateTime.weekday(.abbreviated)
    case ..<60: .dateTime.month(.abbreviated).day()
    default: .dateTime.month(.abbreviated)
    }
  }
}
