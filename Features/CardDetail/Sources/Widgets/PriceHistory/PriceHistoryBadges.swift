import Networking
import SwiftUI

struct PriceChangePill: View {
  let change: PriceChange?
  var insets = EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5)

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let direction = PriceChartStyle.direction(for: change)
    let symbol = Image(systemName: PriceChartStyle.symbol(for: direction))

    Text("\(symbol)\(PriceChartStyle.changeText(for: change))")
      .font(.caption).fontWeight(.medium)
      .monospacedDigit()
      .foregroundStyle(PriceChartStyle.pillForeground(for: direction, in: colorScheme))
      .padding(insets)
      .background(
        PriceChartStyle.pillBackground(for: direction, in: colorScheme),
        in: RoundedRectangle(cornerRadius: 8.0)
      )
  }
}

struct FinishSwatch: View {
  let kind: PriceSeriesKind

  var body: some View {
    Circle()
      .fill(PriceChartStyle.color(for: kind))
      .frame(width: PriceChartStyle.swatchSize, height: PriceChartStyle.swatchSize)
  }
}
