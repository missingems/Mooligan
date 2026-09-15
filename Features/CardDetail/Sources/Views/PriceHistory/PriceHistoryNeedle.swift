import SwiftUI

struct PriceHistoryNeedle: View {
  let interaction: ChartInteraction
  let isEnabled: Bool
  let layout: ScrubLayout

  @Environment(\.colorScheme) private var colorScheme

  private static let bendDepth: CGFloat = 18.0

  var body: some View {
    if isEnabled,
       let anchorX = interaction.anchorX,
       let plotTop = interaction.plotTopY,
       let plotBottom = interaction.plotBottomY,
       layout.headerWidth > 0.0,
       layout.readoutSize.width > 0.0 {
      let isScrubbing = interaction.scrubbedDate != nil
      let x = layout.chartOrigin.x + anchorX
      let readout = layout.readoutOrigin(anchorX: anchorX)
      let start = isScrubbing
        ? CGPoint(x: readout.x + layout.readoutSize.width / 2.0, y: readout.y + layout.readoutSize.height)
        : CGPoint(x: x, y: layout.chartOrigin.y + plotTop)
      let end = CGPoint(x: x, y: layout.chartOrigin.y + plotBottom)

      if end.y > start.y {
        NeedleString(
          start: start,
          end: end,
          bendBottom: max(layout.chartOrigin.y, start.y) + Self.bendDepth
        )
        .stroke(
          PriceChartStyle.gridColor(colorScheme),
          style: StrokeStyle(lineWidth: PriceChartStyle.needleWidth, lineCap: .round, lineJoin: .round)
        )
        .opacity(isScrubbing ? 1.0 : 0.0)
        .allowsHitTesting(false)
      }
    }
  }
}
