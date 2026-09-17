import Networking
import SwiftUI

struct PriceHistoryChart: View {
  let derivedData: ChartDerivedData
  let axis: PriceChartStyle.PriceAxis
  let interaction: ChartInteraction

  var body: some View {
    // Nothing here reads `interaction.plot`: the overlay makes its scale from it on touch, so
    // measuring the plot re-evaluates neither the chart nor its marks.
    ZStack {
      PriceHistoryChartMarks(derivedData: derivedData, axis: axis, interaction: interaction)
    }
    .allowsHitTesting(false)
    .overlay {
      PriceHistoryChartOverlay(derivedData: derivedData, interaction: interaction, priceDomain: axis.domain)
    }
    .coordinateSpace(.named(PlotScale.space))
  }
}
