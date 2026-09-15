import Foundation
import Networking

public enum PriceHistoryState: Equatable, Sendable {
  case loading
  case unavailable
  case failed
  case data(PriceHistorySection)

  static let empty: PriceHistorySection = {
    let end = UTCDay.today
    return PriceHistorySection(
      dateRange: end.addingTimeInterval(-Double(ChartDerivedData.windowInDays) * 86_400)...end
    )
  }()

  var data: PriceHistorySection {
    switch self {
    case .loading, .unavailable, .failed:
      return Self.empty

    case let .data(priceHistorySection):
      return priceHistorySection
    }
  }
}
