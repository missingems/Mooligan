import Charts
import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryChartOverlay: View {
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  let proxy: ChartProxy
  let plot: CGRect
  let needleOvershoot: CGFloat

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
    if let focusDate,
       let focusX = proxy.position(forX: focusDate), focusX.isFinite {
      let height = max(plot.maxY + needleOvershoot, 1.0)

      VibrantVerticalDivider(width: PriceChartStyle.needleWidth)
        .frame(height: height)
        .position(x: plot.minX + focusX, y: plot.maxY - height / 2.0)
        .allowsHitTesting(false)

      ForEach(derivedData.displayedSeries) { series in
        if let point = interaction.point(in: series, at: focusDate),
           let x = proxy.position(forX: point.date),
           let y = proxy.position(forY: point.amount.doubleValue),
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
        .offset(x: entry.x, y: plot.minY + Self.releaseBandInset)
        .allowsHitTesting(false)
    }
  }

  private static let releaseBandInset: CGFloat = 5.0

  private static let releaseCapsuleWidth: CGFloat = 32.0

  private func releasePositions() -> [(release: SetReleaseMarker, x: CGFloat)] {
    let last = max(plot.maxX - Self.releaseCapsuleWidth, plot.minX)

    return derivedData.releases.compactMap { release in
      guard let x = proxy.position(forX: release.date), x.isFinite else { return nil }
      return (release, min(max(plot.minX + x, plot.minX), last))
    }
  }

  private func releaseIcon(_ release: SetReleaseMarker) -> some View {
    IconLazyImage(release.iconURL, tintColor: .primary)
      .frame(
        width: PriceChartStyle.releaseIconSize,
        height: PriceChartStyle.releaseIconSize
      )
      .padding(.horizontal, 7.0)
      .padding(.vertical, 5.0)
      .glassEffect()
      .fixedSize()
      .accessibilityLabel(Text(release.name))
  }

  private func updateInteraction(_ positions: [CGFloat]) {
    guard plot.width > 0 else { return }
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
