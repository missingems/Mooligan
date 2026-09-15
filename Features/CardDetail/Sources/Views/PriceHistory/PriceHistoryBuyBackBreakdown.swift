import SwiftUI

/// The buy back price and ratio for each finish, from the vendor that buys them.
struct PriceHistoryBuyBackBreakdown: View {
  let buyBack: BuyBackSummary

  static let width: CGFloat = 250.0

  var body: some View {
    VStack(alignment: .leading, spacing: 8.0) {
      Text(buyBack.provider.displayName)
        .font(.caption)
        .foregroundStyle(.secondary)

      ForEach(buyBack.finishes) { finish in
        HStack(spacing: 5.0) {
          FinishSwatch(kind: finish.kind)

          Text(finish.label)

          Spacer(minLength: 8.0)

          Text(finish.priceText)
            .monospacedDigit()

          if let ratioText = finish.ratioText {
            Text(ratioText)
              .monospacedDigit()
              .foregroundStyle(.secondary)
          }
        }
        .font(.subheadline)
        .fontDesign(.rounded)
        .lineLimit(1)
      }
    }
    .padding(13.0)
    .frame(width: Self.width, alignment: .leading)
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("priceHistory.buyBack.breakdown")
  }
}
