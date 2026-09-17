import Networking
import SwiftUI

/// The scrub readout, drawn in the chart's coordinate space: a glass needle at the scrubbed day
/// with a dot on each line where it crosses, and a glass capsule over the needle's tip reading the
/// day and its prices. The capsule follows the needle, stopping only at the screen's edges.
///
/// Only in the hierarchy while a scrub is on: hidden with an opacity, its glass was laid out on
/// every scroll frame. It fades in when a scrub starts and fades out where the finger lifted.
struct PriceHistoryScrubReadout: View {
  let display: PriceHistoryDisplay
  let interaction: ChartInteraction
  /// The section's horizontal padding, which the readout may cross to reach the screen's edge.
  let margin: CGFloat

  @State private var readoutSize: CGSize = .zero

  /// Only finishes with a price take part; the others have nothing to read out.
  private var prices: [FinishPrice] { display.pricedFinishes }

  var body: some View {
    ZStack(alignment: .topLeading) {
      if interaction.isScrubbing {
        content.transition(.opacity)
      }
    }
    .animation(.easeOut(duration: 0.2), value: interaction.isScrubbing)
    .allowsHitTesting(false)
  }

  private var content: some View {
    let plot = interaction.plot
    let scale = PlotScale(plot: plot, dates: display.chart.dateRange, prices: display.axis.domain)
    let scrubbedDate = interaction.scrubbedDate ?? display.chart.dateRange.upperBound
    let needleX = scale.x(for: scrubbedDate) ?? plot.midX

    return ZStack(alignment: .topLeading) {
      // The container fuses the dots into the needle where they touch it.
      GlassEffectContainer(spacing: 6.0) {
        ZStack(alignment: .topLeading) {
          needle(at: needleX, plot: plot)
          lineDots(for: scrubbedDate, scale: scale)
        }
      }

      readout(for: scrubbedDate, needleX: needleX, plot: plot)
    }
  }

  /// Where a readout `width` wide should be centred to follow `x` without leaving the screen: the
  /// chart spans the section's content, and `margin` either side of it is still on screen.
  static func center(ofWidth width: CGFloat, at x: CGFloat, chartWidth: CGFloat, margin: CGFloat) -> CGFloat {
    let half = width / 2.0
    let lower = half - margin
    let upper = chartWidth + margin - half
    guard chartWidth > 0.0, lower <= upper else { return chartWidth / 2.0 }
    return min(max(x, lower), upper)
  }

  // MARK: Needle

  /// Three points wide: thicker than a hairline, so the glass reads as an ice needle.
  private func needle(at x: CGFloat, plot: CGRect) -> some View {
    Capsule()
      .fill(.clear)
      .frame(width: 3.0, height: max(plot.height, 3.0))
      .glassEffect(.regular, in: .capsule)
      .position(x: x, y: plot.midY)
  }

  /// A glass dot on each line where the needle crosses it, fused into the needle by the container.
  @ViewBuilder private func lineDots(for scrubbedDate: Date, scale: PlotScale) -> some View {
    ForEach(display.chart.plotSeries) { series in
      if let first = series.points.first?.date,
         let last = series.points.last?.date,
         let value = series.value(at: scrubbedDate),
         let x = scale.x(for: min(max(scrubbedDate, first), last)),
         let y = scale.y(for: value) {
        let color = PriceChartStyle.color(for: series.kind)
        Circle()
          .fill(color)
          .frame(width: 10.0, height: 10.0)
          .glassEffect(.regular.tint(color), in: .circle)
          .position(x: x, y: y)
      }
    }
  }

  // MARK: Readout

  /// The readout hangs by its bottom edge off a one-point anchor at the needle's tip. The anchor
  /// proposes a single point, so the readout fixes its own size or its text would be squeezed to
  /// nothing.
  private func readout(for scrubbedDate: Date, needleX: CGFloat, plot: CGRect) -> some View {
    Color.clear
      .frame(width: 1.0, height: 1.0)
      .overlay(alignment: .bottom) {
        VStack(alignment: .center, spacing: 5.0) {
          Text(day(for: scrubbedDate), format: Date.FormatStyle(timeZone: .gmt).month(.abbreviated).day().year())
            .font(.caption2)
            .foregroundStyle(.secondary)

          HStack(alignment: .top, spacing: 13.0) {
            ForEach(prices) { price in
              column(for: price)
            }
          }
        }
        .padding(EdgeInsets(top: 8.0, leading: 21.0, bottom: 8.0, trailing: 21.0))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 21.0))
        .fixedSize()
        .onGeometryChange(for: CGSize.self) { $0.size } action: { readoutSize = $0 }
      }
      .position(
        x: Self.center(ofWidth: readoutSize.width, at: needleX, chartWidth: interaction.chartSize.width, margin: margin),
        y: plot.minY
      )
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("priceHistory.scrubReadout")
  }

  private func column(for price: FinishPrice) -> some View {
    let text = display.priceText(for: price, interaction: interaction)

    return VStack(alignment: .center, spacing: 1.0) {
      Text(text)
        .contentTransition(.numericText())
        .monospacedDigit()
        .animation(.snappy, value: text)
        .fontDesign(.rounded)
        .font(.body)
        .fontWeight(.semibold)
        .lineLimit(1)
        .foregroundStyle(.primary)

      PriceHistoryToolbarCaption(text: price.label, kind: price.kind, isAvailable: true)
    }
  }

  /// The charted day nearest the finger, so the label agrees with the prices under it.
  private func day(for scrubbedDate: Date) -> Date {
    display.chart.anchorSeries.flatMap { interaction.point(in: $0, at: scrubbedDate)?.date } ?? scrubbedDate
  }
}
