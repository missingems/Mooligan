import DesignComponents
import Foundation
import Networking
import SwiftUI

enum PriceChartStyle {
  static let releaseBandHeight: CGFloat = 38.0

  static let releaseIconSize: CGFloat = 18.0


  static let needleWidth: CGFloat = 1.0

  static func color(for kind: PriceSeriesKind) -> Color {
    switch kind {
    case .normal: DesignComponentsAsset.accentColor.swiftUIColor
    case .foil: .orange
    case .etched: .purple
    }
  }

  static let displayOrder: [PriceSeriesKind] = [.foil, .etched, .normal]

  static func displayRank(_ kind: PriceSeriesKind) -> Int {
    displayOrder.firstIndex(of: kind) ?? displayOrder.count
  }

  static func label(for kind: PriceSeriesKind) -> String {
    switch kind {
    case .normal: String(localized: "Regular")
    case .foil: String(localized: "Foil")
    case .etched: String(localized: "Etched Foil")
    }
  }

  static func trendColor(_ change: PriceChange?) -> Color {
    guard let change, change.isIncrease || change.isDecrease else { return .secondary }
    return change.isIncrease ? .green : .red
  }

  static func changeText(for change: PriceChange) -> String {
    guard let fraction = change.fraction else { return "" }
    return abs(fraction).formatted(.percent.precision(.fractionLength(1)))
  }

  static func changeSymbol(for change: PriceChange) -> String? {
    guard change.isIncrease || change.isDecrease else { return nil }
    return change.isIncrease ? "arrow.up" : "arrow.down"
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

  static func gridColor(_ colorScheme: ColorScheme) -> some ShapeStyle {
    (colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225))
      .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
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

extension Decimal {
  var doubleValue: Double { (self as NSDecimalNumber).doubleValue }
}
