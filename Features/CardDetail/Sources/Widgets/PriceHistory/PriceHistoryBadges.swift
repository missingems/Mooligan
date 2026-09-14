import Networking
import SwiftUI

struct PriceChangePill: View {
  let change: PriceHistoryDisplay.Change
  var insets = EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5)

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let symbol = Image(systemName: PriceChartStyle.symbol(for: change.direction))

    Text("\(symbol)\(change.text)")
      .font(.caption).fontWeight(.medium)
      .monospacedDigit()
      .foregroundStyle(PriceChartStyle.pillForeground(for: change.direction, in: colorScheme))
      .padding(insets)
      .background(
        PriceChartStyle.pillBackground(for: change.direction, in: colorScheme),
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

struct GlassCapsuleAction: View {
  let title: String
  var systemImage: String?
  let accessibilityID: String
  let action: () -> Void

  var body: some View {
    HStack(spacing: 5.0) {
      if let systemImage {
        Image(systemName: systemImage)
      }

      Text(title)
    }
    .font(.subheadline)
    .fontWeight(.semibold)
    .lineLimit(1)
    .padding(.horizontal, 13.0)
    .padding(.vertical, 5.0)
    .contentShape(.capsule)
    .glassEffect(.regular.interactive(), in: .capsule)
    .onTapGesture(perform: action)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
    .accessibilityAction { action() }
    .accessibilityIdentifier(accessibilityID)
  }
}
