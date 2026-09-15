import Networking
import SwiftUI

struct PriceHistoryScrubReadout: View {
  let display: PriceHistoryDisplay
  let interaction: ChartInteraction
  let isEnabled: Bool
  let layout: ScrubLayout
  @Binding var size: CGSize
  @Environment(\.displayScale) private var displayScale
  private var isScrubbing: Bool { interaction.scrubbedDate != nil }
  private var isShown: Bool { isScrubbing && isEnabled }
  
  var body: some View {
    if isShown {
      let frame = isShown
      ? CGRect(origin: layout.readoutOrigin(anchorX: interaction.anchorX), size: size)
      : layout.summaryFrame
      
      rows
        .padding(.horizontal, 13.0)
        .padding(.vertical, 8.0)
        .fixedSize()
        .onGeometryChange(for: CGSize.self) { [displayScale] in $0.size.snapped(to: displayScale) } action: { newSize in
          guard isScrubbing == false || size == .zero, size != newSize else { return }
          size = newSize
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 21.0))
        .offset(x: frame.minX, y: frame.minY)
        .animation(ScrubLayout.slide, value: isScrubbing)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }

  private var rows: some View {
    Grid(alignment: .leading, horizontalSpacing: 5.0, verticalSpacing: 5.0) {
      ForEach(display.chart.series) { series in
        if let index = interaction.pointIndex(for: series),
           let frames = display.scrubFrames[series.kind],
           frames.prices.indices.contains(index) {
          GridRow {
            FinishSwatch(kind: series.kind)

            Text(frames.prices[index])
              .font(.body)
              .fontWeight(.medium)
              .monospaced()
            
            PriceChangePill(change: frames.changes[index])
          }
        }
      }
    }
    .contentTransition(.numericText())
    .animation(isScrubbing ? .snappy(duration: 0.18) : nil, value: readoutDay)
    .lineLimit(1)
    .fixedSize()
  }

  private var readoutDay: Date? {
    display.chart.anchorSeries.flatMap { series in interaction.pointIndex(for: series).map { series.points[$0].date } }
  }
}
