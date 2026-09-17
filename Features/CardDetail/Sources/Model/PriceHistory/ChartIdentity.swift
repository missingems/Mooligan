import Foundation
import Networking

/// What tells one drawn chart from the next: the finishes it plots, how many points each has, and
/// the days it spans and the releases it marks. Landing prices swap the chart under a new identity, so the new chart fades in
/// over the old one instead of Swift Charts interpolating every line, area and axis tick for the
/// length of an animation, which cost main-thread time on each of those frames and read as a
/// stutter when it happened mid-scroll.
struct ChartIdentity: Hashable, Sendable {
  let kinds: [PriceSeriesKind]
  let pointCounts: [Int]
  let dateRange: ClosedRange<Date>
  let releases: [String]

  init(_ derivedData: ChartDerivedData) {
    kinds = derivedData.plotSeries.map(\.kind)
    pointCounts = derivedData.plotSeries.map(\.points.count)
    dateRange = derivedData.dateRange
    releases = derivedData.releases.map(\.id)
  }
}
