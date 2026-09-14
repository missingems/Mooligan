import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryChartOverlay: View {
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  let scale: PlotScale
  let releases: ReleaseMarkerLayout

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack(alignment: .topLeading) {
      needle
        .animation(.snappy(duration: 0.24), value: isScrubbing)

      releaseBand
      releaseTitle
        .animation(.snappy(duration: 0.18), value: releases.entry(under: interaction.needleX)?.release.id)
      ChartTouchReader { positions in updateInteraction(positions) }
    }
    .sensoryFeedback(trigger: scrubbedDay) { previous, current in
      guard current != nil else { return nil }
      return previous == nil ? .impact(weight: .medium) : .selection
    }
    .onChange(of: restingNeedleX, initial: true) {
      interaction.restingNeedleX = restingNeedleX
    }
  }

  private var plot: CGRect { scale.plot }

  private var restingNeedleX: CGFloat? {
    derivedData.anchorSeries?.points.last.flatMap { scale.x(for: $0.date) }
  }

  private var isScrubbing: Bool { interaction.scrubbedDate != nil }

  private var scrubbedDay: Date? {
    guard let scrubbedDate = interaction.scrubbedDate else { return nil }
    return derivedData.anchorSeries.flatMap { interaction.point(in: $0, at: scrubbedDate)?.date }
  }

  @ViewBuilder private var needle: some View {
    if let focusDate = interaction.scrubbedDate {
      ForEach(derivedData.plotSeries) { series in
        if let first = series.points.first?.date,
           let last = series.points.last?.date,
           let value = series.value(at: focusDate),
           let x = scale.x(for: min(max(focusDate, first), last)),
           let y = scale.y(for: value) {
          Circle()
            .fill(PriceChartStyle.color(for: series.kind))
            .frame(width: 8, height: 8)
            .position(x: x, y: y)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
      }
    }
  }

  private var releaseBand: some View {
    ForEach(releases.entries, id: \.release.id) { entry in
      releaseIcon(entry.release)
        .position(entry.iconCenter)
        .allowsHitTesting(false)
    }
  }

  /// The set's name beside its icon while the needle is over it.
  @ViewBuilder private var releaseTitle: some View {
    if isScrubbing, let entry = releases.entry(under: interaction.needleX) {
      let isLeading = releases.titleIsLeading(for: entry)

      Text(entry.release.name)
        .font(.caption2)
        .fontDesign(.serif)
        .foregroundStyle(.primary)
        .multilineTextAlignment(isLeading ? .trailing : .leading)
        .lineLimit(3)
        .frame(width: ReleaseMarkerLayout.titleMaxWidth, alignment: isLeading ? .trailing : .leading)
        .offset(releases.titleOrigin(for: entry, isLeading: isLeading))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .id(entry.release.id)
        .transition(.opacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }

  private func releaseIcon(_ release: SetReleaseMarker) -> some View {
    IconLazyImage(release.iconURL, tintColor: .primary.opacity(0.67))
      .frame(
        width: PriceChartStyle.releaseIconSize,
        height: PriceChartStyle.releaseIconSize
      )
      .accessibilityLabel(Text(release.name))
  }

  private func updateInteraction(_ positions: [CGFloat]) {
    guard plot.width > 0, derivedData.anchorSeries != nil else { return }
    guard let x = positions.first else {
      interaction.endScrub()
      return
    }

    let clamped = min(max(x, plot.minX), plot.maxX)
    guard let date = scale.date(atX: clamped) else { return }
    interaction.scrubbedDate = date
    interaction.needleX = clamped
  }
}

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

/// A hairline from under each release icon to the bottom of the plot, stronger for the release
/// being scrubbed over.
struct PriceHistoryReleaseRules: View {
  let layout: ReleaseMarkerLayout
  let interaction: ChartInteraction

  @Environment(\.displayScale) private var displayScale

  var body: some View {
    let active = interaction.scrubbedDate == nil ? nil : layout.entry(under: interaction.needleX)
    let width = 1.0 / max(displayScale, 1.0)

    ZStack {
      rules(layout.entries.filter { $0 != active })
        .stroke(Color.primary.opacity(0.16), lineWidth: width)

      if let active {
        rules([active])
          .stroke(Color.primary.opacity(0.45), lineWidth: width)
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func rules(_ entries: [ReleaseMarkerLayout.Entry]) -> Path {
    Path { path in
      guard layout.plot.height > 0.0, layout.ruleTop < layout.plot.maxY else { return }
      for entry in entries {
        path.move(to: CGPoint(x: entry.ruleX, y: layout.ruleTop))
        path.addLine(to: CGPoint(x: entry.ruleX, y: layout.plot.maxY))
      }
    }
  }
}
