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

  static func vibrantLabelTint(_ colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.45) : Color.black.opacity(0.5)
  }

  static func vibrantLabelColor(_ colorScheme: ColorScheme) -> some ShapeStyle {
    vibrantLabelTint(colorScheme).blendMode(vibrantBlendMode(colorScheme))
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
