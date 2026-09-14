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

  private static let shape = RoundedRectangle(cornerRadius: 21.0)

  var body: some View {
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
      .opacity(isShown ? 1.0 : 0.0)
      .frame(width: max(frame.width, 0.0), height: max(frame.height, 0.0))
      .clipShape(Self.shape)
      .background {
        // Glass only while the readout is out. The readout itself stays in the hierarchy so it can
        // slide out of the summary, but glass left on it while hidden, even at zero opacity or as
        // identity glass, was resolved again on every frame of every scroll and pager swipe.
        if isShown {
          Color.clear.glassEffect(.regular, in: Self.shape)
        }
      }
      .opacity(isShown ? 1.0 : 0.0)
      .offset(x: frame.minX, y: frame.minY)
      .animation(ScrubLayout.slide, value: isScrubbing)
      .transaction { $0.animation = $0.animation == ScrubLayout.slide ? $0.animation : nil }
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }

  private var rows: some View {
    Grid(alignment: .leading, horizontalSpacing: 5.0, verticalSpacing: 5.0) {
      ForEach(display.chart.series) { series in
        if let index = interaction.pointIndex(for: series),
           let frames = display.scrubFrames[series.kind],
           frames.prices.indices.contains(index) {
          GridRow {
            FinishSwatch(kind: series.kind)

            ZStack(alignment: .leading) {
              Text(display.widestPriceText)
                .hidden()

              Text(frames.prices[index])
            }
            .font(.body)
            .fontWeight(.medium)
            .monospaced()

            ZStack(alignment: .leading) {
              PriceChangePill(change: display.widestChange)
                .hidden()

              PriceChangePill(change: frames.changes[index])
            }
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
