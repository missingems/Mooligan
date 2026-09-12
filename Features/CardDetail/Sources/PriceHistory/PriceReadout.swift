import Foundation
import Networking

struct PriceReadout: Equatable {
  let point: PricePoint
  let change: PriceChange?
  let isScrubbing: Bool
}

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

  func rangeChange(endingAt index: Int) -> PriceChange? {
    guard points.indices.contains(index), index > 0, let first = points.first else { return nil }
    return PriceChange(start: first, end: points[index])
  }

  func readout(at index: Int, isScrubbing: Bool) -> PriceReadout? {
    guard points.indices.contains(index) else { return nil }
    return PriceReadout(
      point: points[index],
      change: rangeChange(endingAt: index),
      isScrubbing: isScrubbing
    )
  }

  var latestReadout: PriceReadout? {
    guard let index = points.indices.last else { return nil }
    return readout(at: index, isScrubbing: false)
  }
}
