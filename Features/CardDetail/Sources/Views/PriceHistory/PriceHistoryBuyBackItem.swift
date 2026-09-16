import Networking
import SwiftUI

struct PriceHistoryBuyBackItem: View {
  let buyBack: BuyBackSummary
  let labels: PriceHistoryLabels

  @State private var isPresentingBreakdown = false

  var body: some View {
    VStack(alignment: .center, spacing: 1) {
      Text(buyBack.ratioText)
        .fontDesign(.serif)
        .font(.body)
        .fontWeight(.medium)
        .lineLimit(1)
        .foregroundStyle(buyBack.isAvailable ? .primary : PriceChartStyle.disabled)
      
      PriceHistoryToolbarCaption(text: labels.buyBack, isAvailable: buyBack.isAvailable)
    }
    .frame(maxWidth: .infinity, minHeight: 34)
    .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11))
    .glassEffect(buyBack.isAvailable ? .regular.interactive() : .regular)
    .onTapGesture { if buyBack.isAvailable { isPresentingBreakdown = true } }
    .disabled(buyBack.isAvailable == false)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(buyBack.isAvailable ? .isButton : [])
    .accessibilityAction { if buyBack.isAvailable { isPresentingBreakdown = true } }
    .accessibilityIdentifier("priceHistory.buyBack")
    .sheet(isPresented: $isPresentingBreakdown) {
      PriceHistoryBuyBackSheet(buyBack: buyBack, labels: labels)
    }
  }
}
