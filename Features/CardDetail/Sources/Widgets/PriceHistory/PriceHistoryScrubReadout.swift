import Networking
import SwiftUI

struct PriceHistoryScrubReadout: View {
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  let currencyCode: String
  let isEnabled: Bool
  let layout: ScrubLayout
  @Binding var size: CGSize

  @Environment(\.displayScale) private var displayScale

  private var isScrubbing: Bool { interaction.scrubbedDate != nil }

  private var isShown: Bool { isScrubbing && isEnabled }

  var body: some View {
    let origin = layout.readoutOrigin(anchorX: interaction.anchorX)

    rows
      .padding(.horizontal, 13.0)
      .padding(.vertical, 8.0)
      .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 21.0))
      .onGeometryChange(for: CGSize.self) { $0.size.snapped(to: displayScale) } action: { newSize in
        guard isScrubbing == false || size == .zero, size != newSize else { return }
        size = newSize
      }
      .scaleEffect(isShown ? 1.0 : 0.8, anchor: .bottom)
      .opacity(isShown ? 1.0 : 0.0)
      .offset(x: origin.x, y: origin.y)
      .animation(ScrubLayout.slide, value: isScrubbing)
      .transaction { $0.animation = $0.animation == ScrubLayout.slide ? $0.animation : nil }
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }

  private var rows: some View {
    Grid(alignment: .leading, horizontalSpacing: 5.0, verticalSpacing: 5.0) {
      ForEach(derivedData.series) { series in
        if let readout = interaction.readout(for: series) {
          GridRow {
            FinishSwatch(kind: series.kind)

            ZStack(alignment: .leading) {
              Text(derivedData.widestAmount, format: PriceChartStyle.price(currencyCode))
                .hidden()

              Text(readout.point.amount, format: PriceChartStyle.price(currencyCode))
            }
            .font(.body)
            .fontWeight(.medium)
            .monospaced()

            ZStack(alignment: .leading) {
              PriceChangePill(change: derivedData.widestChange)
                .hidden()

              PriceChangePill(change: readout.change)
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
    derivedData.anchorSeries.flatMap { interaction.readout(for: $0)?.point.date }
  }
}
