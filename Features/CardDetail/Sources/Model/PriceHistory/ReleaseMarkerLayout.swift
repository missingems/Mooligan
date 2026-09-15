import DesignComponents
import Networking
import SwiftUI

/// Where each set release sits on the chart: a rule at its release date, its icon along the top of
/// the plot kept inside the plot's edges, and where its title goes while scrubbing over it.
struct ReleaseMarkerLayout: Equatable {
  struct Entry: Equatable {
    let release: SetReleaseMarker
    let ruleX: CGFloat
    let iconCenter: CGPoint
  }

  static let iconInset: CGFloat = 3.0
  static let titleGap: CGFloat = 5.0
  static let titleMaxWidth: CGFloat = 96.0

  let plot: CGRect
  let entries: [Entry]

  init(releases: [SetReleaseMarker], scale: PlotScale) {
    let plot = scale.plot
    let half = PriceChartStyle.releaseIconSize / 2.0
    let first = plot.minX + half
    let last = max(plot.maxX - half, first)

    self.plot = plot
    entries = releases.compactMap { release in
      guard let x = scale.x(for: release.date) else { return nil }
      return Entry(
        release: release,
        ruleX: x,
        iconCenter: CGPoint(x: min(max(x, first), last), y: plot.minY + half + Self.iconInset)
      )
    }
  }

  /// Rules start just under the icons, so they never run through them.
  var ruleTop: CGFloat { plot.minY + PriceChartStyle.releaseIconSize + Self.iconInset * 2.0 }

  /// The release whose icon the needle is over, the nearest one when icons overlap.
  func entry(under needleX: CGFloat?) -> Entry? {
    guard let needleX else { return nil }
    let reach = PriceChartStyle.releaseIconSize / 2.0
    return entries
      .filter { abs($0.iconCenter.x - needleX) <= reach }
      .min { abs($0.iconCenter.x - needleX) < abs($1.iconCenter.x - needleX) }
  }

  /// A title sits on its icon's leading side, and moves to the trailing side only when a title of
  /// the maximum width would run past the plot's leading edge.
  func titleIsLeading(for entry: Entry) -> Bool {
    entry.iconCenter.x - PriceChartStyle.releaseIconSize / 2.0 - Self.titleGap - Self.titleMaxWidth >= plot.minX
  }

  /// The top-leading corner of the title's box, level with the top of the icon.
  func titleOrigin(for entry: Entry, isLeading: Bool) -> CGSize {
    let half = PriceChartStyle.releaseIconSize / 2.0
    let x = isLeading
      ? entry.iconCenter.x - half - Self.titleGap - Self.titleMaxWidth
      : entry.iconCenter.x + half + Self.titleGap
    return CGSize(width: x, height: entry.iconCenter.y - half)
  }
}
