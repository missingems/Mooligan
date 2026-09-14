import Networking
import SwiftUI

struct PriceHistoryHeaderView: View {
  let title: String
  let summary: [PriceHistoryDisplay.SummaryItem]
  let interaction: ChartInteraction
  @Binding var summaryFrame: CGRect

  @Environment(\.displayScale) private var displayScale

  private static let columnSpacing: CGFloat = 13.0

  /// Lays out exactly like a real column, so it gives the row its height without any prices.
  private static let sizingItem = PriceHistoryDisplay.SummaryItem(kind: .normal, label: " ", priceText: " ", change: nil)

  var body: some View {
    VStack(alignment: .leading, spacing: 8.0) {
      Text(title).font(.headline)
      summaryRow
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var isScrubbing: Bool { interaction.scrubbedDate != nil }

  private var summaryRow: some View {
    // The row's size comes from a stand-in column that never changes; the real columns sit in an
    // overlay. Prices and change pills arriving then re-lay out only this row, instead of making
    // the card detail page and the pager around it measure everything again.
    column(Self.sizingItem)
      .hidden()
      .lineLimit(1)
      .frame(maxWidth: .infinity, alignment: .leading)
      .overlay(alignment: .topLeading) { columns }
      .onGeometryChange(for: CGRect.self) { [displayScale] geometry in
        let frame = geometry.frame(in: .named(ScrubLayout.space))
        return CGRect(origin: frame.origin.snapped(to: displayScale), size: frame.size.snapped(to: displayScale))
      } action: { frame in
        if summaryFrame != frame { summaryFrame = frame }
      }
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
        ZStack(alignment: .leading) {
          PriceChangePill(change: .flat)
            .frame(width: 0.0, alignment: .leading)
            .hidden()

          Text(item.priceText)
            .font(.body)
            .fontWeight(.medium)
            .monospaced()
            .id(item.priceText)
            .transition(.opacity)
        }

        if let change = item.change {
          PriceChangePill(change: change)
            .fixedSize()
            .transition(.opacity)
        }
      }

      HStack(spacing: 5.0) {
        FinishSwatch(kind: item.kind)

        Text(item.label)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }
    }
  }
}

extension CGFloat {
  func snapped(to scale: CGFloat) -> CGFloat {
    guard scale > 0.0, isFinite else { return self }
    return (self * scale).rounded() / scale
  }
}

extension CGSize {
  func snapped(to scale: CGFloat) -> CGSize {
    CGSize(width: width.snapped(to: scale), height: height.snapped(to: scale))
  }
}

extension CGPoint {
  func snapped(to scale: CGFloat) -> CGPoint {
    CGPoint(x: x.snapped(to: scale), y: y.snapped(to: scale))
  }
}
