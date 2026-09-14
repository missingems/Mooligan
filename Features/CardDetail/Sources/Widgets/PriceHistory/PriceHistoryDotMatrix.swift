import SwiftUI

struct PriceHistoryDotMatrix: View {
  let plot: CGRect?
  let tickRows: [CGFloat]
  var isHighlighted = false

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let tint = isHighlighted ? PriceChartStyle.vibrantDotHighlight(colorScheme) : PriceChartStyle.vibrantDotTint(colorScheme)
    let radius = isHighlighted ? DotMatrixLayout.highlightRadius : DotMatrixLayout.radius
    let blendMode: GraphicsContext.BlendMode = colorScheme == .dark ? .plusLighter : .plusDarker

    Canvas { context, size in
      let layout = DotMatrixLayout(plot: plot ?? CGRect(origin: .zero, size: size), tickRows: tickRows)
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
  static let highlightRadius: CGFloat = 1.1

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
  @Entry var priceHistoryPlaceholderAnimates: Bool = true
}

/// The dot matrix with a wave of brighter, larger dots rolling across it, shown while prices load.
struct PriceHistoryLoadingDotMatrix: View {
  let plot: CGRect?
  let tickRows: [CGFloat]

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.priceHistoryPlaceholderAnimates) private var animates
  @State private var phase: CGFloat = -1.0

  var body: some View {
    PriceHistoryDotMatrix(plot: plot, tickRows: tickRows)
      .overlay {
        if animates, reduceMotion == false {
          // Both matrices are drawn once and the wave is a gradient mask sliding over the bright one,
          // so only an offset animates; redrawing the canvas itself would be a GPU draw on the main
          // thread every frame.
          PriceHistoryDotMatrix(plot: plot, tickRows: tickRows, isHighlighted: true)
            .mask {
              LinearGradient(stops: Self.wave, startPoint: .leading, endPoint: .trailing)
                .visualEffect { [phase] content, proxy in
                  content.offset(x: phase * proxy.size.width)
                }
            }
            .onAppear {
              withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                phase = 1.0
              }
            }
        }
      }
      .accessibilityHidden(true)
  }

  /// A soft crest: a squared raised cosine, fading to nothing at both edges of the band.
  private static let wave: [Gradient.Stop] = (0...16).map { step in
    let location = Double(step) / 16.0
    let crest = 0.5 + 0.5 * cos((location - 0.5) * 2.0 * .pi)
    return Gradient.Stop(color: .white.opacity(crest * crest), location: location)
  }
}
