import Foundation
import Networking

/// An item in the toolbar, and the sheet tapping it opens.
enum PriceHistoryToolbarEntry: Hashable, Sendable, Identifiable {
  case finish(PriceSeriesKind)
  case buyBack

  var id: String {
    switch self {
    case let .finish(kind): "finish.\(kind.rawValue)"
    case .buyBack: "buyBack"
    }
  }
}
