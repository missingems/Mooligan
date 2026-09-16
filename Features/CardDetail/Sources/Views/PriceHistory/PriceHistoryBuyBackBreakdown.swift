import SwiftUI

/// The buy back price for each finish, and that price as a share of the vendor's own retail price.
struct PriceHistoryBuyBackBreakdown: View {
  let buyBack: BuyBackSummary

  var body: some View {
    VStack(alignment: .leading, spacing: 13.0) {
      ForEach(buyBack.finishes) { finish in
        HStack(spacing: 5.0) {
          FinishSwatch(kind: finish.kind)

          Text(finish.label)

          Spacer(minLength: 8.0)

          Text(finish.priceText)
            .monospacedDigit()

          Text(finish.ratioText ?? PriceChartStyle.missingValue)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(minWidth: 44.0, alignment: .trailing)
        }
        .font(.body)
        .fontDesign(.rounded)
        .lineLimit(1)
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("priceHistory.buyBack.breakdown")
  }
}
