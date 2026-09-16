import Networking
import SwiftUI

/// The scrub choreography, drawn in the chart's coordinate space and hidden until a scrub starts.
///
/// A copy of each priced finish's toolbar capsule sits exactly over it, placed from the frame the
/// capsule reports; a finish without a price has no copy and is left alone. When a scrub starts the
/// copies show at once while the toolbar dims, and three motions follow, each starting before the
/// last has finished: the copies slide onto one another into one capsule, their text blurring away;
/// that capsule balls up to the size of a chart dot as it flies to the foot of the needle; and while
/// it is still in flight the readout fades in over the needle's tip as the ball is absorbed into
/// the needle. The needle is there from the first frame, with a glass dot on each line at the
/// scrubbed day fused into it. The readout then follows the needle, stopping only at the screen's
/// edges.
/// Releasing fades it all where it stands. Every motion is a short, bounce-free curve.
struct PriceHistoryScrubReadout: View {
  let display: PriceHistoryDisplay
  let interaction: ChartInteraction
  /// The section's horizontal padding, which the readout may cross to reach the screen's edge.
  let margin: CGFloat
  /// Pins the choreography to one step, for snapshots of each stage.
  var fixedPhase: ScrubReadoutPhase? = nil

  @State private var animatedPhase: ScrubReadoutPhase = .start
  /// Where the needle stood when the finger lifted, so it fades in place instead of jumping.
  @State private var lastScrubbedDate: Date?
  @State private var readoutSize: CGSize = .zero

  private var phase: ScrubReadoutPhase { fixedPhase ?? animatedPhase }
  /// Only finishes with a price take part; the others have nothing to read out.
  private var prices: [FinishPrice] { display.pricedFinishes }

  var body: some View {
    let plot = interaction.plot
    let scale = PlotScale(plot: plot, dates: display.chart.dateRange, prices: display.axis.domain)
    let scrubbedDate = interaction.scrubbedDate ?? lastScrubbedDate ?? display.chart.dateRange.upperBound
    let needleX = scale.x(for: scrubbedDate) ?? plot.midX

    // Always in the hierarchy, only shown while scrubbing: it appears the moment a scrub starts
    // and fades once it ends.
    ZStack(alignment: .topLeading) {
      // The container fuses glass closer than 6 points, under the toolbar's 8-point gap, so the
      // copies only fuse once they touch.
      GlassEffectContainer(spacing: 6.0) {
        ZStack(alignment: .topLeading) {
          needle(at: needleX, plot: plot)
          lineDots(for: scrubbedDate, scale: scale)
          proxies(needleX: needleX, plot: plot)
        }
      }

      // Outside the container: inside one, an opacity above a glass effect never reaches the
      // glass, and the readout fades in and out as a whole.
      readout(for: scrubbedDate, needleX: needleX, plot: plot)
    }
    .opacity(interaction.isScrubbing ? 1.0 : 0.0)
    .animation(interaction.isScrubbing ? nil : .easeOut(duration: 0.2), value: interaction.isScrubbing)
    .onChange(of: interaction.scrubbedDate) { _, date in
      if let date { lastScrubbedDate = date }
    }
    .task(id: interaction.isScrubbing) {
      guard fixedPhase == nil else { return }
      guard interaction.isScrubbing else {
        // Nothing moves on release: the readout fades where it is, and only once it is gone does
        // the choreography snap back to its start for the next scrub.
        try? await Task.sleep(for: .seconds(0.2))
        if Task.isCancelled { return }
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { animatedPhase = .start }
        return
      }
      await choreograph()
    }
    .allowsHitTesting(false)
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

  // MARK: Choreography

  /// Three motions that all but overlap: the copies gather; a beat later the ball flies to the
  /// needle's foot; another beat later the readout opens while the ball is absorbed. State is
  /// written from the main actor each time.
  private func choreograph() async {
    withAnimation(.smooth(duration: 0.11)) { animatedPhase = .gathered }
    try? await Task.sleep(for: .milliseconds(11))
    if Task.isCancelled { return }
    withAnimation(.smooth(duration: 0.17)) { animatedPhase = .balled }
    try? await Task.sleep(for: .milliseconds(22))
    if Task.isCancelled { return }
    withAnimation(.smooth(duration: 0.22)) { animatedPhase = .expanded }
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

  // MARK: Proxies

  /// A copy of each priced finish's capsule, price and caption alike, drawn over the frame the
  /// toolbar reported for it. Gathering, the copies move to one centre at one size, so they are a
  /// single capsule; leaving the toolbar they ball up as they fly to the needle's foot, text
  /// blurring away; landing, the ball shrinks to the needle's width and vanishes inside it. Inside
  /// a glass container an opacity above the glass never reaches it, so the ball is hidden by
  /// shrinking rather than fading.
  @ViewBuilder private func proxies(needleX: CGFloat, plot: CGRect) -> some View {
    // The toolbar reports its frames in the section's coordinate space; this view draws in the
    // chart's, which sits at `chartFrame` within the section.
    let chartFrame = interaction.chartFrame
    let frames = interaction.toolbarFrames.mapValues { $0.offsetBy(dx: -chartFrame.minX, dy: -chartFrame.minY) }
    let capsules = prices.compactMap { frames[$0.kind] }
    let gatheredCenter = CGPoint(
      x: capsules.map(\.midX).reduce(0.0, +) / CGFloat(max(capsules.count, 1)),
      y: capsules.map(\.midY).reduce(0.0, +) / CGFloat(max(capsules.count, 1))
    )
    let gatheredSize = capsules.first?.size ?? .zero
    let isBall = phase.proxyIsBall
    let isAbsorbed = phase.proxyIsAbsorbed
    // The text blurs away as the copies slide onto one another, so they never overlap legibly.
    let hidesText = phase >= .gathered
    // A chart dot's 10 points in flight, then the needle's 3 once absorbed.
    let ballSize: CGFloat = isAbsorbed ? 3.0 : 10.0

    ForEach(prices) { price in
      if let frame = frames[price.kind] {
        let size: CGSize = switch phase {
        case .start: frame.size
        case .gathered: gatheredSize
        case .balled, .expanded: CGSize(width: ballSize, height: ballSize)
        }
        let center: CGPoint = switch phase {
        case .start: CGPoint(x: frame.midX, y: frame.midY)
        case .gathered: gatheredCenter
        case .balled, .expanded: CGPoint(x: needleX, y: plot.maxY - ballSize / 2.0)
        }

        VStack(alignment: .center, spacing: 1.0) {
          Text(price.priceText)
            .fontDesign(.rounded)
            .font(.body)
            .fontWeight(.semibold)
            .lineLimit(1)

          PriceHistoryToolbarCaption(text: price.label, kind: price.kind, isAvailable: true)
        }
        .blur(radius: hidesText ? 6.0 : 0.0)
        .opacity(hidesText ? 0.0 : 1.0)
        .frame(width: size.width, height: size.height)
        // A ball of clear glass on a plain background has no visible edge; a little smoke makes it
        // read while it flies.
        .glassEffect(.regular.tint(isBall && isAbsorbed == false ? Color.primary.opacity(0.18) : .clear), in: .capsule)
        .position(center)
      }
    }
  }

  // MARK: Readout

  /// The readout hangs by its bottom edge off a one-point anchor just under the needle's tip. The
  /// anchor proposes a single point, so the readout fixes its own size or its text would be
  /// squeezed to nothing.
  private func readout(for scrubbedDate: Date, needleX: CGFloat, plot: CGRect) -> some View {
    let isOpen = phase.readoutIsOpen

    return Color.clear
      .frame(width: 1.0, height: 1.0)
      .overlay(alignment: .bottom) {
        VStack(alignment: .center, spacing: 2.0) {
          Text(day(for: scrubbedDate), format: Date.FormatStyle(timeZone: .gmt).month(.abbreviated).day().year())
            .font(.caption)
            .foregroundStyle(.secondary)
            .opacity(isOpen ? 1.0 : 0.0)

          HStack(alignment: .top, spacing: 13.0) {
            ForEach(prices) { price in
              column(for: price)
            }
          }
          .padding(EdgeInsets(top: 8.0, leading: 21.0, bottom: 8.0, trailing: 21.0))
          .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 21.0))
          .opacity(isOpen ? 1.0 : 0.0)
        }
        .fixedSize()
        .onGeometryChange(for: CGSize.self) { $0.size } action: { readoutSize = $0 }
      }
      .position(
        x: isOpen
          ? Self.center(ofWidth: readoutSize.width, at: needleX, chartWidth: interaction.chartFrame.width, margin: margin)
          : needleX,
        y: plot.minY + 13.0
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
