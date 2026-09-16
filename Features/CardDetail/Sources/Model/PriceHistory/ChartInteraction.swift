import Foundation
import Networking
import Observation

@Observable
final class ChartInteraction {
  var scrubbedDate: Date? {
    didSet {
      let scrubbing = scrubbedDate != nil
      if scrubbing != isScrubbing { isScrubbing = scrubbing }
    }
  }

  /// Flips only when a scrub starts or ends. Views that dim or pop something up while scrubbing
  /// read this rather than `scrubbedDate`, so they are not re-evaluated on every move of the finger.
  private(set) var isScrubbing = false

  /// The chart's plot area in its own coordinate space; `.zero` until the chart has laid out.
  var plot: CGRect = .zero

  /// The chart's frame in the price section's coordinate space; `.zero` until it has laid out.
  var chartFrame: CGRect = .zero

  /// Each finish capsule's frame in the toolbar, in the price section's coordinate space, so the
  /// scrub choreography can draw its copy exactly over it.
  var toolbarFrames: [PriceSeriesKind: CGRect] = [:]

  func endScrub() {
    guard scrubbedDate != nil else { return }
    scrubbedDate = nil
  }

  @ObservationIgnored
  private var lastFoundIndices: [String: Int] = [:]

  /// The scrubbed day's point in `series`, or its latest point when nothing is scrubbed.
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
