import Networking
import SwiftUI

struct PriceHistoryChart: View {
  let derivedData: ChartDerivedData
  let axis: PriceChartStyle.PriceAxis
  let interaction: ChartInteraction
  var isLoading = false

  var body: some View {
    let _ = Self._printChanges()
    let scale = PlotScale(plot: interaction.plot, dates: derivedData.plotDateRange, prices: axis.domain)
    let releases = ReleaseMarkerLayout(releases: derivedData.releases, scale: scale)

    PriceHistoryChartMarks(derivedData: derivedData, axis: axis, interaction: interaction)
      .background {
        let tickRows = axis.ticks.compactMap(scale.y(for:))
        ZStack {
          PriceHistoryDotMatrix(plot: scale.plot, tickRows: tickRows)

          if isLoading {
            PriceHistoryLoadingDotMatrix(plot: scale.plot, tickRows: tickRows)
          }

          // Behind the marks, so a release's rule never crosses over the price lines.
          PriceHistoryReleaseRules(layout: releases, interaction: interaction)
        }
      }
      .overlay {
        if scale.isMeasured {
          PriceHistoryChartOverlay(derivedData: derivedData, interaction: interaction, scale: scale, releases: releases)
        }
      }
      .coordinateSpace(.named(PlotScale.space))
  }
}
