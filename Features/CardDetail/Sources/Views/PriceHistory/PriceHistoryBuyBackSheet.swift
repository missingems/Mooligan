import DesignComponents
import Networking
import SwiftUI

/// The figures behind the toolbar's buy back ratio: the vendor they come from, what it pays for each
/// finish and that as a share of its own retail price, and a link to its buylist.
struct PriceHistoryBuyBackSheet: View {
  let buyBack: BuyBackSummary
  let labels: PriceHistoryLabels

  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 13.0) {
          HStack {
            Text(labels.source)
              .foregroundStyle(.secondary)

            Spacer(minLength: 8.0)

            Text(buyBack.provider.displayName)
          }
          .font(.body)
          .lineLimit(1)
          .accessibilityElement(children: .combine)
          .accessibilityIdentifier("priceHistory.buyBack.source")

          VibrantDivider()

          PriceHistoryBuyBackBreakdown(buyBack: buyBack)

          Text(labels.buyBackExplanation)
            .font(.footnote)
            .foregroundStyle(.secondary)

          if let url = buyBack.sellURL {
            GlassCapsuleAction(
              title: labels.sell(to: buyBack.provider.displayName),
              accessibilityID: "priceHistory.buyBack.sell"
            ) {
              openURL(url)
            }
            .padding(.top, 8.0)
          }
        }
        .safeAreaPadding(.horizontal, systemHorizontalMargin)
        .padding(.top, 13.0)
      }
      .navigationTitle(labels.buyBack)
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .close) {
            dismiss()
          }
          .accessibilityIdentifier("priceHistory.buyBack.close")
        }
      }
    }
    .presentationDetents([.medium])
  }
}
