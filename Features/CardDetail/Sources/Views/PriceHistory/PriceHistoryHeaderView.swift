import Networking
import SwiftUI

struct PriceHistoryHeaderView: View {
  let title: String
  let summary: [PriceHistoryDisplay.SummaryItem]
  let interaction: ChartInteraction
  @Binding var summaryFrame: CGRect

  @Environment(\.displayScale) private var displayScale

  private static let columnSpacing: CGFloat = 13.0

  var body: some View {
    VStack(alignment: .leading, spacing: 8.0) {
      Text(title).font(.headline)
      summaryRow
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var isScrubbing: Bool { interaction.scrubbedDate != nil }

  private var summaryRow: some View {
    columns
      .opacity(isScrubbing ? 0.35 : 1.0)
      .saturation(isScrubbing ? 0.0 : 1.0)
      .animation(ScrubLayout.slide, value: isScrubbing)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("priceHistory.summary")
  }

  private var columns: some View {
    HStack(alignment: .top, spacing: Self.columnSpacing) {
      ForEach(summary) { item in
        column(item)
      }
    }
    .lineLimit(1)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func column(_ item: PriceHistoryDisplay.SummaryItem) -> some View {
    VStack(alignment: .leading, spacing: 3.0) {
      HStack(alignment: .center, spacing: 5.0) {
        Text(item.priceText)
          .font(.body)
          .fontWeight(.medium)
          .monospaced()

        PriceChangePill(change: item.change)
          .fixedSize()
      }

      HStack(spacing: 5.0) {
        FinishSwatch(kind: item.kind)

        Text(item.label)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}
