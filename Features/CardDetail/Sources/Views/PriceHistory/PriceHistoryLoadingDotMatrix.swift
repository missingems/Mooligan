import SwiftUI

/// The wave of highlighted dots drawn over `PriceHistoryDotMatrix` while prices load.
struct PriceHistoryLoadingDotMatrix: View {
  let plot: CGRect?
  let tickRows: [CGFloat]

  @Environment(\.priceHistoryPlaceholderAnimates) private var animates
  @State private var phase: CGFloat = -1.0

  var body: some View {
    if animates {
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
        .accessibilityHidden(true)
    }
  }

  private static let wave: [Gradient.Stop] = (0...16).map { step in
    let location = Double(step) / 16.0
    let crest = 0.5 + 0.5 * cos((location - 0.5) * 2.0 * .pi)
    return Gradient.Stop(color: .white.opacity(crest * crest), location: location)
  }
}
