import Networking
import SwiftUI

struct PriceChangePill: View {
  let change: PriceHistoryDisplay.Change
  var insets = EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5)

  var body: some View {
    let symbol = Image(systemName: PriceChartStyle.symbol(for: change.direction))

    (change.isKnown ? Text("\(symbol)\(change.text)") : Text(change.text))
      .font(.caption2)
      .fontWeight(.medium)
      .monospacedDigit()
      .foregroundStyle(PriceChartStyle.pillForeground(for: change.direction))
      .padding(insets)
      .background(
        PriceChartStyle.pillBackground(for: change.direction),
        in: RoundedRectangle(cornerRadius: 8.0)
      )
  }
}
