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
        FinishSwatch(kind: kind, isAvailable: isAvailable)
      }

      Text(text)
        .font(.caption)
        .foregroundStyle(tint)
    }
    .lineLimit(1)
  }
  
  private var tint: AnyShapeStyle {
    guard isAvailable else { return AnyShapeStyle(PriceChartStyle.disabled) }
    return kind.map { AnyShapeStyle(PriceChartStyle.color(for: $0)) } ?? AnyShapeStyle(.secondary)
  }
}
