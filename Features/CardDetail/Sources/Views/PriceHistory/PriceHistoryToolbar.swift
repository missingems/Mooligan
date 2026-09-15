import Networking
import SwiftUI

/// Each finish's price, opening the card's TCGplayer page, and the buy back ratio, which expands into
/// its breakdown. Three items share one row; four go two to a row.
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
  }

  @ViewBuilder private func item(_ entry: PriceHistoryToolbarEntry) -> some View {
    switch entry {
    case let .finish(kind):
      if let price = display.price(for: kind) {
        PriceHistoryToolbarItem(
          value: display.priceText(for: price, interaction: interaction),
          caption: price.label,
          kind: kind,
          isAvailable: price.isAvailable,
          onTap: { if let url = display.tcgplayerURL { openURL(url) } }
        )
        .accessibilityIdentifier("priceHistory.price.\(kind.rawValue)")
      }

    case .buyBack:
      PriceHistoryBuyBackItem(buyBack: display.buyBack, caption: labels.buyBack, interaction: interaction)
    }
  }
}
