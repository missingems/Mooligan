import DesignComponents
import Foundation
import Networking
import SwiftUI

enum PriceChartStyle {
  static let releaseIconSize: CGFloat = 24.0

  static let swatchSize: CGFloat = 5.0

  static let cardCornerRadius: CGFloat = 21.0

  static let needleWidth: CGFloat = 1.0

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

  enum ChangeDirection {
    case up
    case down
    case flat
  }

  static func direction(for change: PriceChange?) -> ChangeDirection {
    guard let fraction = change?.fraction else { return .flat }
    let tenths = (fraction * 1000.0).rounded()
    if tenths < 0 { return .down }
    return tenths > 0 ? .up : .flat
  }

  static func tint(for direction: ChangeDirection) -> Color {
    switch direction {
    case .up: .green
    case .down: .red
    case .flat: .gray
    }
  }

  static func pillForeground(for direction: ChangeDirection, in colorScheme: ColorScheme) -> Color {
    guard direction != .flat else { return Color(.secondaryLabel) }
    let tint = tint(for: direction)
    return colorScheme == .dark ? tint : tint.mix(with: .black, by: 0.3)
  }

  static func pillBackground(for direction: ChangeDirection, in colorScheme: ColorScheme) -> Color {
    guard direction != .flat else { return Color(.tertiarySystemFill) }
    return tint(for: direction).opacity(colorScheme == .dark ? 0.2 : 0.14)
  }

  static func symbol(for direction: ChangeDirection) -> String {
    direction == .down ? "arrow.down" : "arrow.up"
  }

  static let missingValue = "—"

  static let flatChangeText = 0.0.formatted(.percent.precision(.fractionLength(1)))

  static func changeText(for change: PriceChange?) -> String {
    guard let fraction = change?.fraction else { return flatChangeText }
    return abs(fraction).formatted(.percent.precision(.fractionLength(1)))
  }

  static func price(_ code: String) -> Decimal.FormatStyle.Currency {
    .currency(code: code)
      .presentation(.narrow)
      .precision(.fractionLength(2))
  }

  static func axisPrice(
    _ code: String,
    fractionDigits: Int
  ) -> FloatingPointFormatStyle<Double>.Currency {
    .currency(code: code)
      .presentation(.narrow)
      .precision(.fractionLength(fractionDigits))
  }

  static func vibrantBlendMode(_ colorScheme: ColorScheme) -> BlendMode {
    colorScheme == .dark ? .plusLighter : .plusDarker
  }

  static func gridColor(_ colorScheme: ColorScheme) -> some ShapeStyle {
    (colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225))
      .blendMode(vibrantBlendMode(colorScheme))
  }

  static func vibrantDotTint(_ colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.35)
  }

  static func borderGradient(_ colorScheme: ColorScheme) -> LinearGradient {
    let tint = colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225)
    return LinearGradient(colors: [tint.opacity(0.0), tint], startPoint: .top, endPoint: .bottom)
  }

  static func vibrantLabelTint(_ colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.45) : Color.black.opacity(0.5)
  }

  static func vibrantLabelColor(_ colorScheme: ColorScheme) -> some ShapeStyle {
    vibrantLabelTint(colorScheme).blendMode(vibrantBlendMode(colorScheme))
  }

  struct PriceAxis: Equatable, Sendable {
    let domain: ClosedRange<Double>
    let ticks: [Double]
    let fractionDigits: Int
    var tickLabels: [String] = []

    func labeled(currencyCode: String) -> PriceAxis {
      var axis = self
      axis.tickLabels = ticks.map { $0.formatted(PriceChartStyle.axisPrice(currencyCode, fractionDigits: fractionDigits)) }
      return axis
    }

    func label(at index: Int) -> String {
      tickLabels.indices.contains(index) ? tickLabels[index] : ""
    }
  }

  static let fallbackPriceAxis = PriceAxis(domain: 0.0...1.0, ticks: [0.0, 0.5, 1.0], fractionDigits: 2)

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

    let count = Int(((upper - lower) / step).rounded())
    let ticks = (0...count).map { index in
      ((lower + Double(index) * step) / step).rounded() * step
    }
    let isWhole = ticks.allSatisfy { ($0 * 100.0).rounded().truncatingRemainder(dividingBy: 100.0) == 0.0 }

    return PriceAxis(domain: lower...upper, ticks: ticks, fractionDigits: isWhole ? 0 : 2)
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

  static func spanText(of dates: ClosedRange<Date>) -> String {
    let days = spanInDays(of: dates)
    switch days {
    case ..<14:
      return String(localized: "Past \(days) Days")
    case ..<60:
      let weeks = max(1, Int((Double(days) / 7.0).rounded()))
      return weeks == 1 ? String(localized: "Past Week") : String(localized: "Past \(weeks) Weeks")
    default:
      let months = max(1, Int((Double(days) / 30.0).rounded()))
      return months == 1 ? String(localized: "Past Month") : String(localized: "Past \(months) Months")
    }
  }

  static func statWindow(forSpanDays days: Int) -> (label: String, days: Int?) {
    switch days {
    case 75...: ("3M", 90)
    case 28...: ("1M", 30)
    case 7...: ("1W", 7)
    default: ("\(max(days, 1))D", nil)
    }
  }

  static func axisDateStyle(forDays days: Int) -> Date.FormatStyle {
    switch days {
    case ..<10: .dateTime.weekday(.abbreviated)
    case ..<60: .dateTime.month(.abbreviated).day()
    default: .dateTime.month(.abbreviated)
    }
  }
}

extension Decimal {
  var doubleValue: Double { (self as NSDecimalNumber).doubleValue }
}
