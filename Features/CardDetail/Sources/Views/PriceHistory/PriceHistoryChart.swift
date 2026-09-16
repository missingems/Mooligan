import Networking
import SwiftUI

struct PriceHistoryChart: View {
  let derivedData: ChartDerivedData
  let axis: PriceChartStyle.PriceAxis
  let interaction: ChartInteraction

  var body: some View {
    let scale = PlotScale(plot: interaction.plot, dates: derivedData.dateRange, prices: axis.domain)
    let identity = ChartIdentity(derivedData)

    ZStack {
      // Landing prices replace the chart rather than animating it into place. Animated, Swift
      // Charts interpolated every line, area and axis tick on each frame for the whole animation;
      // a crossfade draws each chart once and only blends the two.
      PriceHistoryChartMarks(derivedData: derivedData, axis: axis, interaction: interaction)
        .id(identity)
        .transition(.opacity)
    }
    .animation(.easeInOut(duration: 0.35), value: identity)
    .allowsHitTesting(false)
    .overlay {
      PriceHistoryChartOverlay(derivedData: derivedData, interaction: interaction, scale: scale)
    }
    .coordinateSpace(.named(PlotScale.space))
  }
}
