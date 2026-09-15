import Foundation
import Networking

enum PriceHistoryLoadOutcome: Equatable, Sendable {
  case loaded([PriceSeriesRequest: PriceHistory])
  case noData
  case failed
}
