import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryChartOverlay: View {
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  let scale: PlotScale

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack(alignment: .topLeading) {
      needle
        .animation(.snappy(duration: 0.24), value: isScrubbing)

      releaseBand
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
    ForEach(releasePositions(), id: \.release.id) { entry in
      releaseIcon(entry.release)
        .position(x: entry.x, y: plot.minY + PriceChartStyle.releaseIconSize / 2.0 + 3.0)
        .allowsHitTesting(false)
    }
  }

  private func releasePositions() -> [(release: SetReleaseMarker, x: CGFloat)] {
    let half = PriceChartStyle.releaseIconSize / 2.0
    let first = plot.minX + half
    let last = max(plot.maxX - half, first)

    return derivedData.releases.compactMap { release in
      guard let x = scale.x(for: release.date) else { return nil }
      return (release, min(max(x, first), last))
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
