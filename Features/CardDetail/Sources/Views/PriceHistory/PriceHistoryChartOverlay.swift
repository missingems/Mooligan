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

    // The padding before the first date has no prices, so the needle stops where the data starts.
    let dataStart = scale.x(for: derivedData.dateRange.lowerBound) ?? plot.minX
    let clamped = min(max(x, dataStart), plot.maxX)
    guard let date = scale.date(atX: clamped) else { return }
    interaction.scrubbedDate = date
    interaction.needleX = clamped
  }
}
