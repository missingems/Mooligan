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
      dots
        .animation(.snappy(duration: 0.24), value: isScrubbing)

      ChartTouchReader { positions in updateInteraction(positions) }
    }
    .sensoryFeedback(trigger: scrubbedDay) { previous, current in
      guard current != nil else { return nil }
      return previous == nil ? .impact(weight: .medium) : .selection
    }
  }

  private var plot: CGRect { scale.plot }

  private var isScrubbing: Bool { interaction.scrubbedDate != nil }

  private var scrubbedDay: Date? {
    guard let scrubbedDate = interaction.scrubbedDate else { return nil }
    return derivedData.anchorSeries.flatMap { interaction.point(in: $0, at: scrubbedDate)?.date }
  }

  /// A hairline through the scrubbed day, from the top of the plot to the bottom, under the dots.
  @ViewBuilder private var needle: some View {
    if let focusDate = interaction.scrubbedDate, let x = scale.x(for: focusDate) {
      Rectangle()
        .fill(PriceChartStyle.gridTint(colorScheme))
        .frame(width: PriceChartStyle.needleWidth, height: plot.height)
        .compositingGroup()
        .blendMode(PriceChartStyle.vibrantBlendMode(colorScheme))
        .position(x: x, y: plot.midY)
        .allowsHitTesting(false)
        .transition(.opacity)
    }
  }

  @ViewBuilder private var dots: some View {
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

  private func updateInteraction(_ positions: [CGFloat]) {
    guard plot.width > 0, derivedData.anchorSeries != nil else { return }
    guard let x = positions.first else {
      interaction.endScrub()
      return
    }

    guard let date = scale.date(atX: min(max(x, plot.minX), plot.maxX)) else { return }
    interaction.scrubbedDate = date
  }
}
