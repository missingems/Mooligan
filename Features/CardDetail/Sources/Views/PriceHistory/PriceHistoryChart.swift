import Networking
import SwiftUI

struct PriceHistoryChart: View {
  let derivedData: ChartDerivedData
  let axis: PriceChartStyle.PriceAxis
  let interaction: ChartInteraction

  var body: some View {
    let scale = PlotScale(plot: interaction.plot, dates: derivedData.dateRange, prices: axis.domain)

    PriceHistoryChartMarks(derivedData: derivedData, axis: axis, interaction: interaction)
      .allowsHitTesting(false)
      .overlay {
        PriceHistoryChartOverlay(derivedData: derivedData, interaction: interaction, scale: scale)
      }
      .coordinateSpace(.named(PlotScale.space))
  }
}
