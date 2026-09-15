import Networking
import SwiftUI

struct PlotScale: Equatable {
  static let space = "PriceHistory.chart"

  let plot: CGRect
  let dates: ClosedRange<Date>
  let prices: ClosedRange<Double>

  var isMeasured: Bool { plot.width > 0.0 && plot.height > 0.0 }

  func x(for date: Date) -> CGFloat? {
    let span = dates.upperBound.timeIntervalSince(dates.lowerBound)
    guard isMeasured, span > 0.0 else { return nil }
    let x = plot.minX + CGFloat(date.timeIntervalSince(dates.lowerBound) / span) * plot.width
    return x.isFinite ? x : nil
  }

  func y(for price: Double) -> CGFloat? {
    let span = prices.upperBound - prices.lowerBound
    guard isMeasured, span > 0.0 else { return nil }
    let y = plot.maxY - CGFloat((price - prices.lowerBound) / span) * plot.height
    return y.isFinite ? y : nil
  }

  func date(atX x: CGFloat) -> Date? {
    guard isMeasured else { return nil }
    let fraction = Double((min(max(x, plot.minX), plot.maxX) - plot.minX) / plot.width)
    return dates.lowerBound.addingTimeInterval(fraction * dates.upperBound.timeIntervalSince(dates.lowerBound))
  }

  static func drawable(_ rect: CGRect, snappedTo displayScale: CGFloat) -> CGRect {
    let normalized = rect.standardized
    guard
      normalized.origin.x.isFinite,
      normalized.origin.y.isFinite,
      normalized.width.isFinite,
      normalized.height.isFinite,
      normalized.width > 0,
      normalized.height > 0
    else {
      return .zero
    }
    return CGRect(
      origin: normalized.origin.snapped(to: displayScale),
      size: normalized.size.snapped(to: displayScale)
    )
  }
}
