import Networking
import SwiftUI

struct PriceHistoryToolbarItem: View {
  let value: String
  let caption: String
  let kind: PriceSeriesKind
  let isAvailable: Bool
  let onTap: () -> Void

  var body: some View {
    VStack(alignment: .center, spacing: 1.0) {
      Text(value)
        .fontDesign(.rounded)
        .font(.body)
        .fontWeight(.semibold)
        .lineLimit(1)
        .foregroundStyle(isAvailable ? .primary : PriceChartStyle.disabled)

      PriceHistoryToolbarCaption(text: caption, kind: kind, isAvailable: isAvailable)
    }
    .frame(maxWidth: .infinity, minHeight: 34)
    .padding(EdgeInsets(top: 5, leading: 11, bottom: 5, trailing: 11))
    .glassEffect(isAvailable ? .regular.interactive() : .regular)
    .onTapGesture { if isAvailable { onTap() } }
    .disabled(isAvailable == false)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isAvailable ? .isLink : [])
    .accessibilityAction { if isAvailable { onTap() } }
  }
}
