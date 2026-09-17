import Foundation
import Networking

extension PriceHistorySection.Series {
  func indexOfPoint(nearest date: Date) -> Int? {
    guard points.isEmpty == false else { return nil }

    var low = 0
    var high = points.count - 1
    while low < high {
      let mid = (low + high) / 2
      if points[mid].date < date { low = mid + 1 } else { high = mid }
    }

    guard low > 0 else { return low }
    let previous = abs(points[low - 1].date.timeIntervalSince(date))
    let candidate = abs(points[low].date.timeIntervalSince(date))
    return previous <= candidate ? low - 1 : low
  }
}
