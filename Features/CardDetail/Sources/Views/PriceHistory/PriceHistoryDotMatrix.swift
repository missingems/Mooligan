import SwiftUI

struct PriceHistoryDotMatrix: View {
  let plot: CGRect?
  let tickRows: [CGFloat]
  var isHighlighted = false

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale
  
  var body: some View {
    let radius = 1 / displayScale
    let tint = isHighlighted ? PriceChartStyle.vibrantDotHighlight(colorScheme) : PriceChartStyle.vibrantDotTint(colorScheme)
    let blendMode: GraphicsContext.BlendMode = colorScheme == .dark ? .plusLighter : .plusDarker

    Canvas { context, size in
      let layout = DotMatrixLayout(plot: plot ?? CGRect(origin: .zero, size: size), tickRows: tickRows)
      context.blendMode = blendMode

      var path = Path()
      for point in layout.dots() {
        path.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * displayScale, height: radius * displayScale))
      }
      context.fill(path, with: .color(tint))
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}
