import Networking
import SwiftUI

/// The touch reader that drives the scrub, and its haptics. The needle and the dots on each line are
/// glass and belong to the scrub readout, which draws them.
struct PriceHistoryChartOverlay: View {
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  let priceDomain: ClosedRange<Double>

  var body: some View {
    ChartTouchReader { positions in updateInteraction(positions) }
      .sensoryFeedback(trigger: scrubbedDay) { previous, current in
        guard current != nil else { return nil }
        return previous == nil ? .impact(weight: .medium) : .selection
      }
  }

  /// Made on touch, not in `body`, so the plot being measured does not re-evaluate the overlay.
  private var scale: PlotScale {
    PlotScale(plot: interaction.plot, dates: derivedData.dateRange, prices: priceDomain)
  }

  private var plot: CGRect { interaction.plot }

  private var scrubbedDay: Date? {
    guard let scrubbedDate = interaction.scrubbedDate else { return nil }
    return derivedData.anchorSeries.flatMap { interaction.point(in: $0, at: scrubbedDate)?.date }
  }

  private func updateInteraction(_ positions: [CGFloat]) {
    guard plot.width > 0, derivedData.anchorSeries != nil else { return }
    guard let x = positions.first else {
      interaction.endScrub()
      return
    }

    let plot = plot
    guard let date = scale.date(atX: min(max(x, plot.minX), plot.maxX)) else { return }
    interaction.scrubbedDate = date
  }
}
