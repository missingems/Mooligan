import Networking
import SwiftUI

/// A finish's price in a glass capsule with its caption underneath, filling its share of its row.
/// Without a price it reads as a greyed-out dash and ignores taps.
struct PriceHistoryToolbarItem: View {
  let value: String
  let caption: String
  let kind: PriceSeriesKind
  let isAvailable: Bool
  let onTap: () -> Void

  var body: some View {
    VStack(alignment: .center, spacing: 3.0) {
      PriceHistoryToolbarValue(text: value, isAvailable: isAvailable)
        .glassEffect(isAvailable ? .regular.interactive() : .regular)

      PriceHistoryToolbarCaption(text: caption, kind: kind, isAvailable: isAvailable)
    }
    .frame(maxWidth: .infinity)
    .onTapGesture { if isAvailable { onTap() } }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isAvailable ? .isLink : [])
    .accessibilityAction { if isAvailable { onTap() } }
  }
}
