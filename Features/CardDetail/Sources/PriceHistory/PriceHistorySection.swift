import Foundation
import Networking
import ScryfallKit

public struct PriceHistorySection: Equatable, Sendable {
  public struct Series: Identifiable, Equatable, Sendable {
    public let kind: PriceSeriesKind
    public let points: [PricePoint]
    public let priceRange: ClosedRange<Double>
    public let dateRange: ClosedRange<Date>

    public var id: String { kind.rawValue }

    init?(kind: PriceSeriesKind, points: [PricePoint]) {
      let values = points.map { ($0.amount as NSDecimalNumber).doubleValue }
        .filter(\.isFinite)
      guard
        points.count >= 2,
        let low = values.min(),
        let high = values.max(),
        let first = points.first?.date,
        let last = points.last?.date,
        last > first
      else {
        return nil
      }
      self.kind = kind
      self.points = points
      self.priceRange = low...max(high, low)
      self.dateRange = first...last
    }
  }

  public let series: [Series]
  public let currency: String
  public let releases: [SetReleaseMarker]
  public let priceRange: ClosedRange<Double>
  public let dateRange: ClosedRange<Date>

  init(series: [Series] = [], currency: String = "", releases: [SetReleaseMarker] = []) {
    let low = series.map(\.priceRange.lowerBound).min() ?? 0
    let high = series.map(\.priceRange.upperBound).max() ?? 0
    let first = series.map(\.dateRange.lowerBound).min() ?? Date()
    let last = series.map(\.dateRange.upperBound).max() ?? Date()

    self.series = series
    self.currency = currency
    self.releases = releases
    self.priceRange = low...max(high, low)
    self.dateRange = first...max(last, first.addingTimeInterval(86_400))
  }
}

public enum PriceHistoryState: Equatable, Sendable {
  case loading
  case unavailable
  case data(PriceHistorySection)

  static let empty = PriceHistorySection()

  var data: PriceHistorySection {
    switch self {
    case .loading, .unavailable:
      return Self.empty

    case let .data(priceHistorySection):
      return priceHistorySection
    }
  }
}
