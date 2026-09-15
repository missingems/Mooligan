import Networking
import SwiftUI

/// The finish swatch and name, or the buy back label, under a toolbar capsule.
struct PriceHistoryToolbarCaption: View {
  let text: String
  var kind: PriceSeriesKind?
  let isAvailable: Bool

  var body: some View {
    HStack(spacing: 2.0) {
      if let kind {
        FinishSwatch(kind: kind)
      }

      Text(text)
        .font(.caption)
        .foregroundStyle(kind.map(PriceChartStyle.color(for:)) ?? .secondary)
    }
    .lineLimit(1)
    .opacity(isAvailable ? 1.0 : 0.5)
  }
}
