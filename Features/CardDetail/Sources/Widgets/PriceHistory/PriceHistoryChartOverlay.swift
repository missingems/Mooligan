import Charts
import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryChartOverlay: View {
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  let proxy: ChartProxy
  let plot: CGRect

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack(alignment: .topLeading) {
      needle
        .animation(.snappy(duration: 0.24), value: isScrubbing)

      releaseBand
      ChartTouchReader { positions in updateInteraction(positions) }
    }
    .sensoryFeedback(trigger: scrubbedDay) { _, current in
      current == nil ? nil : .selection
    }
    .onChange(of: restingNeedleX, initial: true) {
      interaction.restingNeedleX = restingNeedleX
    }
    .onChange(of: plot.minY, initial: true) {
      interaction.plotTopY = plot.minY
    }
    .onChange(of: plot.maxY, initial: true) {
      interaction.plotBottomY = plot.maxY
    }
  }

  private var restingNeedleX: CGFloat? {
    guard let date = derivedData.anchorSeries?.points.last?.date,
          let x = proxy.position(forX: date), x.isFinite
    else {
      return nil
    }
    return plot.minX + x
  }

  private var isScrubbing: Bool { interaction.scrubbedDate != nil }

  private var scrubbedDay: Date? {
    guard let scrubbedDate = interaction.scrubbedDate else { return nil }
    return derivedData.anchorSeries.flatMap { interaction.point(in: $0, at: scrubbedDate)?.date }
  }

  private var focusDate: Date? {
    interaction.scrubbedDate ?? derivedData.anchorSeries?.points.last?.date
  }

  @ViewBuilder private var needle: some View {
    if let focusDate {
      ForEach(derivedData.plotSeries) { series in
        if let first = series.points.first?.date,
           let last = series.points.last?.date,
           let value = series.value(at: focusDate),
           let x = proxy.position(forX: min(max(focusDate, first), last)),
           let y = proxy.position(forY: value),
           x.isFinite, y.isFinite {
          Circle()
            .fill(PriceChartStyle.color(for: series.kind))
            .frame(width: 8.44, height: 8.44)
            .position(x: plot.minX + x, y: plot.minY + y)
            .allowsHitTesting(false)
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
      guard let x = proxy.position(forX: release.date), x.isFinite else { return nil }
      return (release, min(max(plot.minX + x, first), last))
    }
  }

  private func releaseIcon(_ release: SetReleaseMarker) -> some View {
    IconLazyImage(release.iconURL, tintColor: PriceChartStyle.vibrantLabelTint(colorScheme))
      .frame(
        width: PriceChartStyle.releaseIconSize,
        height: PriceChartStyle.releaseIconSize
      )
      .blendMode(PriceChartStyle.vibrantBlendMode(colorScheme))
      .accessibilityLabel(Text(release.name))
  }

  private func updateInteraction(_ positions: [CGFloat]) {
    guard plot.width > 0, derivedData.anchorSeries != nil else { return }
    guard let x = positions.first else {
      interaction.endScrub()
      return
    }

    let clamped = min(max(x - plot.minX, 0.0), plot.width)
    guard let date = proxy.value(atX: clamped, as: Date.self) else { return }
    interaction.scrubbedDate = date
    interaction.needleX = plot.minX + clamped
  }
}
