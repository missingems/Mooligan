import Networking
import SwiftUI

struct PriceHistoryToolbar: View {
  let display: PriceHistoryDisplay
  let labels: PriceHistoryLabels
  let interaction: ChartInteraction

  @Environment(\.openURL) private var openURL

  var body: some View {
    VStack(spacing: 8.0) {
      ForEach(display.toolbarEntries.toolbarRows(), id: \.first) { row in
        HStack(alignment: .top, spacing: 8.0) {
          ForEach(row) { entry in
            item(entry)
          }
        }
      }
    }
    .opacity(interaction.isScrubbing ? 0.35 : 1.0)
    .animation(.snappy, value: interaction.isScrubbing)
  }

  @ViewBuilder private func item(_ entry: PriceHistoryToolbarEntry) -> some View {
    switch entry {
    case let .finish(kind):
      if let price = display.price(for: kind) {
        PriceHistoryToolbarItem(
          value: price.priceText,
          caption: price.label,
          kind: kind,
          isAvailable: price.isAvailable,
          onTap: { if let url = display.tcgplayerURL { openURL(url) } }
        )
        .accessibilityIdentifier("priceHistory.price.\(kind.rawValue)")
        // The scrub choreography draws a copy of this capsule exactly over it.
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("priceHistory.section")) } action: { frame in
          if interaction.toolbarFrames[kind] != frame { interaction.toolbarFrames[kind] = frame }
        }
      }

    case .buyBack:
      PriceHistoryBuyBackItem(buyBack: display.buyBack, labels: labels)
    }
  }
}
