import SwiftUI

struct PriceHistoryDotMatrix: View {
  let plot: CGRect?
  let tickRows: [CGFloat]

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let tint = PriceChartStyle.vibrantDotTint(colorScheme)
    let blendMode: GraphicsContext.BlendMode = colorScheme == .dark ? .plusLighter : .plusDarker

    Canvas { context, size in
      let layout = DotMatrixLayout(plot: plot ?? CGRect(origin: .zero, size: size), tickRows: tickRows)
      let radius = DotMatrixLayout.radius
      context.blendMode = blendMode

      var path = Path()
      for point in layout.dots() {
        path.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2.0, height: radius * 2.0))
      }
      context.fill(path, with: .color(tint))
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

struct DotMatrixLayout: Equatable {
  static let targetSpacing: CGFloat = 11.0
  static let radius: CGFloat = 0.6

  let plot: CGRect
  let tickRows: [CGFloat]

  var spacing: CGFloat {
    let sorted = tickRows.sorted()
    guard sorted.count >= 2 else { return Self.targetSpacing }
    let gap = sorted[1] - sorted[0]
    guard gap > 0.0 else { return Self.targetSpacing }
    let divisions = max(1.0, (gap / Self.targetSpacing).rounded())
    return gap / divisions
  }

  func dots() -> [CGPoint] {
    guard plot.width > 0.0, plot.height > 0.0 else { return [] }

    let spacing = spacing
    let anchorY = tickRows.min() ?? plot.minY
    let firstRow = anchorY - ((anchorY - plot.minY) / spacing).rounded(.down) * spacing
    let firstColumn = plot.maxX - (plot.width / spacing).rounded(.down) * spacing

    var dots: [CGPoint] = []
    var y = firstRow
    while y <= plot.maxY + 0.5 {
      var x = firstColumn
      while x <= plot.maxX + 0.5 {
        dots.append(CGPoint(x: x, y: y))
        x += spacing
      }
      y += spacing
    }
    return dots
  }
}

extension EnvironmentValues {
  @Entry var priceHistoryShimmers: Bool = true
}

struct PriceHistoryChartPlaceholder: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.priceHistoryShimmers) private var shimmers
  @State private var phase: CGFloat = -1.0

  var body: some View {
    PriceHistoryDotMatrix(plot: nil, tickRows: [])
      .overlay {
        if shimmers, reduceMotion == false {
          LinearGradient(
            colors: [.clear, Color.primary.opacity(0.08), .clear],
            startPoint: .leading,
            endPoint: .trailing
          )
          .scaleEffect(x: 0.6, anchor: .center)
          .offset(x: 0.0)
          .visualEffect { [phase] content, proxy in
            content.offset(x: phase * proxy.size.width)
          }
          .blendMode(.plusLighter)
          .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
              phase = 1.0
            }
          }
        }
      }
      .clipped()
      .accessibilityHidden(true)
  }
}
