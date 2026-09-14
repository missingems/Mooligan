import Foundation
import Networking
import Observation

@Observable
final class ChartInteraction {
  var scrubbedDate: Date?

  var needleX: CGFloat?

  var restingNeedleX: CGFloat?

  /// The chart's plot area in its own coordinate space; `.zero` until the chart has laid out.
  var plot: CGRect = .zero

  var plotTopY: CGFloat? { plot.isEmpty ? nil : plot.minY }

  var plotBottomY: CGFloat? { plot.isEmpty ? nil : plot.maxY }

  var anchorX: CGFloat? { needleX ?? restingNeedleX }

  func endScrub() {
    guard scrubbedDate != nil || needleX != nil else { return }
    scrubbedDate = nil
    needleX = nil
  }

  @ObservationIgnored
  private var lastFoundIndices: [String: Int] = [:]

  func pointIndex(for series: PriceHistorySection.Series) -> Int? {
    guard let scrubbedDate else { return series.points.indices.last }
    return index(in: series, nearest: scrubbedDate)
  }

  func point(in series: PriceHistorySection.Series, at date: Date) -> PricePoint? {
    index(in: series, nearest: date).map { series.points[$0] }
  }

  private func index(in series: PriceHistorySection.Series, nearest date: Date) -> Int? {
    let points = series.points
    guard points.isEmpty == false else { return nil }

    if let last = lastFoundIndices[series.id], points.indices.contains(last) {
      let candidate = points[last]
      if abs(candidate.date.timeIntervalSince(date)) < 86_400 {
        var best = last
        var minimum = abs(candidate.date.timeIntervalSince(date))

        if last > 0 {
          let previous = abs(points[last - 1].date.timeIntervalSince(date))
          if previous < minimum {
            best = last - 1
            minimum = previous
          }
        }
        if last < points.count - 1, abs(points[last + 1].date.timeIntervalSince(date)) < minimum {
          best = last + 1
        }

        lastFoundIndices[series.id] = best
        return best
      }
    }

    let found = series.indexOfPoint(nearest: date)
    lastFoundIndices[series.id] = found
    return found
  }
}
