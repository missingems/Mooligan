import Charts
import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

/// Price history for the card currently on screen.
///
/// A pure renderer: the fetch and every derivation live in `CardDetailFeature`,
/// so this view holds nothing but its own interaction state. See
/// `PriceHistorySection` for why that matters to the pager.
///
/// The section is always laid out, in all three states. An absent section that
/// appears when a fetch lands grows the scroll content under the reader, and the
/// page jumps; a card with no history says so in place instead.
struct PriceHistoryChartView: View, Equatable {
  /// A finish's price as Scryfall quotes it today.
  ///
  /// Shown the moment the screen opens, and independently of the chart. The
  /// history comes from MTGGraphQL and can be slow, rate limited, or simply
  /// missing for a printing — but Scryfall's own numbers arrived with the card
  /// itself, so there is no reason for "no history yet" to also mean "no price".
  struct Quote: Identifiable, Equatable {
    let label: String
    let amount: Decimal

    var id: String { label }
  }

  private let state: PriceHistoryState
  private let quotes: [Quote]
  private let title: String
  private let sourceLabel: String
  private let unavailableLabel: String

  /// How many legend rows to hold space for: one per finish this printing was
  /// made in, which is what the series below end up being.
  private let legendRows: Int

  /// One legend row: a caption-height line with its own vertical padding.
  /// Scaled, so the space reserved for the legend is still the space it takes
  /// at the reader's text size rather than at the default one.
  @ScaledMetric(relativeTo: .caption) private var legendRowHeight = 23.0

  /// The space the legend occupies, including the padding above it.
  private var legendHeight: CGFloat {
    8.0 + CGFloat(max(legendRows, 1)) * legendRowHeight
  }

  @Environment(\.colorScheme) private var colorScheme

  /// The finish the reader has isolated, if any. `nil` draws every finish.
  @State private var isolatedKind: PriceSeriesKind?

  /// The plot's rectangle inside the chart, resolved from Swift Charts' anchor.
  @State private var plot: CGRect = .zero
  @State private var interaction = ChartInteraction()

  /// Touch state lives on a reference type rather than in `@State`.
  ///
  /// `chartOverlay` hands its content an escaping closure, and writing this from
  /// there through `@State` measurably did not redraw: the values arrived, the
  /// guards passed, and the chart kept showing the previous frame. Holding the
  /// state on an observed object made the same writes land, so the struct copy
  /// the closure captures is not a reliable path back to a `@State` box here.
  @Observable
  final class ChartInteraction {
    /// The date under the reader's finger while scrubbing.
    var scrubbedDate: Date?
  }

  /// Compares the data it draws, so the one store change that matters to this
  /// view — the history landing — rebuilds it and the others do not. The scrub
  /// and the isolated finish are `@State` and survive the comparison.
  nonisolated static func == (lhs: PriceHistoryChartView, rhs: PriceHistoryChartView) -> Bool {
    lhs.state == rhs.state
      && lhs.quotes == rhs.quotes
      && lhs.title == rhs.title
      && lhs.sourceLabel == rhs.sourceLabel
      && lhs.unavailableLabel == rhs.unavailableLabel
      && lhs.legendRows == rhs.legendRows
  }

  init(
    state: PriceHistoryState,
    quotes: [Quote] = [],
    title: String,
    sourceLabel: String,
    unavailableLabel: String,
    legendRows: Int
  ) {
    self.state = state
    self.quotes = quotes
    self.title = title
    self.sourceLabel = sourceLabel
    self.unavailableLabel = unavailableLabel
    self.legendRows = legendRows
  }

  var body: some View {
    VibrantDivider()
      .safeAreaPadding(.leading, systemHorizontalMargin)

    VStack(alignment: .leading, spacing: 5.0) {
      header
      todaysQuotes

      Group {
        switch state {
        case .loading:
          placeholder(.shimmer)

        case .unavailable:
          placeholder(.message(unavailableLabel))

        case let .data(section):
          chart(for: section)
            // Tall enough to carry the marker band as well as the plot. Not
            // clipped here: `AreaMark`'s explicit floor keeps the marks inside,
            // and clipping cut the top off an expanded release symbol — the
            // container's own clip shape does the job at the right radius.
            .frame(height: Self.chartHeight)
            // Swift Charts does not re-lay-out its axes when the trait
            // collection flips; the y axis and sometimes the whole plot survive
            // as a stale, zero-sized layer until an unrelated gesture forces a
            // pass. Rebuilding on the scheme is the only way out of that.
            //
            // Whether a scrub is in progress used to be part of this identity
            // too, to force the focus marks to be torn down on release. That
            // could not stay: the scrub reader is a `UIView` living in this
            // chart's own overlay, so changing identity on the first moved
            // pixel destroyed the view holding the touch. The finger carried
            // on, nothing was listening, and the dot stopped where the scrub
            // began and stayed there after the finger lifted. The focus
            // drawing moved out of the chart instead — see `focusOverlay`.
            .id(colorScheme)
        }
      }
      // The same filled, 13pt box the Information tiles and the buy links use,
      // so the chart reads as one more widget on the page rather than a bare
      // drawing floating between two of them.
      .padding(Self.chartInset)
      .background(Color(.systemFill))
      .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
      .padding(.top, 10.0)

      // Held open whether or not there is a legend to put in it.
      //
      // This is the one part of the section whose size depends on the fetch: the
      // header, today's quotes and the chart box are the same height in all
      // three states. Letting it grow when the history lands meant the section
      // got taller under a reader who was already scrolling past it, and
      // everything below moved — which is the jolt, and no amount of confining
      // the re-render fixes it. Reserved from the printing's own finishes, which
      // are known the moment the card is, so the box is the right size before
      // there is anything to draw in it.
      ZStack(alignment: .top) {
        if case let .data(section) = state {
          legend(for: section)
        }
      }
      .frame(height: legendHeight, alignment: .top)
    }
    // Plain padding rather than `safeAreaPadding`: an inset safe area feeds into
    // the chart's plot-area arithmetic, and this section has nothing that needs
    // to bleed to the edge.
    .padding(.horizontal, systemHorizontalMargin)
    .padding(.vertical, 13.0)
  }

  /// Matches `InformationView`'s tiles, the call-to-action button and the buy
  /// links. 8pt is this screen's chip radius and 21pt its grouped-list radius;
  /// 13pt is the one for a widget-sized box.
  static let cornerRadius: CGFloat = 13.0
  static let chartInset: CGFloat = 10.0
  static let chartHeight: CGFloat = 200.0

}

// MARK: - Derived data

private extension PriceHistoryChartView {
  /// What the chart actually draws.
  ///
  /// A card whose foil is many times its regular flattens the cheaper line to a
  /// straight edge on a shared axis, so a finish can be isolated to get the axis
  /// back. Every finish stays in the legend either way — the filter is a way in
  /// and out, not a mode you can get stuck in.
  func displayedSeries(of section: PriceHistorySection) -> [PriceHistorySection.Series] {
    guard let isolatedKind else { return section.series }
    return section.series.filter { $0.kind == isolatedKind }
  }

  /// Extents of whatever is drawn — the isolated finish, or all of them.
  ///
  /// Both are measured when the section is built, so this is a lookup rather
  /// than a pass over every point on each redraw.
  func extents(
    of section: PriceHistorySection
  ) -> (price: ClosedRange<Double>, date: ClosedRange<Date>) {
    guard
      let isolatedKind,
      let only = section.series.first(where: { $0.kind == isolatedKind })
    else {
      return (section.priceRange, section.dateRange)
    }
    return (only.priceRange, only.dateRange)
  }

  /// Nearest observation to a date, by binary search.
  ///
  /// Points are sorted ascending by date, and this runs for every series on
  /// every frame of a scrub, so the linear scan it replaces was the one piece of
  /// per-frame work that grew with the length of the history.
  func nearestPoint(in series: PriceHistorySection.Series, to date: Date) -> PricePoint? {
    let points = series.points
    guard points.isEmpty == false else { return nil }

    var low = 0
    var high = points.count - 1
    while low < high {
      let mid = (low + high) / 2
      if points[mid].date < date { low = mid + 1 } else { high = mid }
    }

    // `low` is the first point at or after `date`; its predecessor may be closer.
    let candidate = points[low]
    guard low > 0 else { return candidate }
    let previous = points[low - 1]
    return abs(previous.date.timeIntervalSince(date)) <= abs(candidate.date.timeIntervalSince(date))
      ? previous
      : candidate
  }

  var focusDate: Date? { interaction.scrubbedDate }

  /// What a legend row reports for one finish: the price at the focus (or the
  /// latest), and the move across the span shown.
  func readout(
    for series: PriceHistorySection.Series
  ) -> (point: PricePoint, change: PriceChange?)? {
    guard let last = series.points.last else { return nil }

    if let scrubbedDate = interaction.scrubbedDate,
       let point = nearestPoint(in: series, to: scrubbedDate) {
      guard let first = series.points.first, first.date != point.date else {
        return (point, nil)
      }
      return (point, PriceChange(start: first, end: point))
    }

    return (last, series.points.change)
  }

  func trend(_ change: PriceChange?) -> Color {
    guard let change, change.isIncrease || change.isDecrease else { return .secondary }
    return change.isIncrease ? .green : .red
  }

  /// Distinct per finish rather than per direction. With two lines on one plot a
  /// green/red trend colour would say nothing about which line is which.
  func color(for kind: PriceSeriesKind) -> Color {
    switch kind {
    case .normal: DesignComponentsAsset.accentColor.swiftUIColor
    case .foil: .orange
    case .etched: .purple
    }
  }

  func label(for kind: PriceSeriesKind) -> String {
    switch kind {
    case .normal: String(localized: "Regular")
    case .foil: String(localized: "Foil")
    case .etched: String(localized: "Etched Foil")
    }
  }
}

// MARK: - Header, placeholder and legend

private extension PriceHistoryChartView {
  var header: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8.0) {
      Text(title)
        .font(.headline)

      Spacer(minLength: 8.0)

      if case let .data(section) = state {
        Text(spanText(for: section))
          .font(.caption)
          .foregroundStyle(.secondary)
          .contentTransition(.numericText())
      }

      Text(sourceLabel)
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
  }

  /// Today's prices, straight from the card. Never waits on anything.
  @ViewBuilder
  var todaysQuotes: some View {
    if quotes.isEmpty == false {
      HStack(spacing: 14.0) {
        ForEach(quotes) { quote in
          HStack(spacing: 4.0) {
            Text(quote.label)
              .font(.caption2)
              .foregroundStyle(.secondary)

            Text(quote.amount, format: .currency(code: "USD"))
              .font(.subheadline.weight(.semibold).monospacedDigit())
          }
        }

        Spacer(minLength: 0)
      }
      .lineLimit(1)
      .minimumScaleFactor(0.8)
    }
  }

  enum PlaceholderKind {
    case shimmer
    case message(String)
  }

  @ViewBuilder
  func placeholder(_ kind: PlaceholderKind) -> some View {
    switch kind {
    case .shimmer:
      // Still, not shimmering. `shimmering()` animates a gradient *mask*, which
      // is an offscreen pass on every frame for as long as it runs — over an
      // area this size, inside a scroll view, for the whole time the history is
      // in flight. That is exactly the window the screen was stuttering in.
      RoundedRectangle(cornerRadius: Self.cornerRadius - Self.chartInset)
        .fill(.quaternary)
        .frame(height: Self.chartHeight)

    case let .message(text):
      VStack(spacing: 6.0) {
        Image(systemName: "chart.line.uptrend.xyaxis")
          .font(.title2)
          .foregroundStyle(.tertiary)

        Text(text)
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal, 21.0)
      .frame(maxWidth: .infinity)
      .frame(height: Self.chartHeight)
    }
  }

  /// Legend and finish filter in one.
  ///
  /// Every finish is drawn at once by default, so each needs a permanent price
  /// and colour key — a segmented control would have hidden half the chart's own
  /// content. Tapping a row isolates that finish and tapping it again restores
  /// the rest, which is the escape hatch for a card whose foil is worth many
  /// times its regular.
  func legend(for section: PriceHistorySection) -> some View {
    VStack(alignment: .leading, spacing: 2.0) {
      ForEach(section.series) { entry in
        if let readout = readout(for: entry) {
          legendRow(for: entry, readout: readout, canFilter: section.series.count > 1)
        }
      }
    }
    .padding(.top, 8.0)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func legendRow(
    for entry: PriceHistorySection.Series,
    readout: (point: PricePoint, change: PriceChange?),
    canFilter: Bool
  ) -> some View {
    // A card with one finish has nothing to filter to, so the row is a plain
    // legend rather than a disabled button — `.disabled` dims its content, which
    // made a foil-only card look switched off when it was simply the only line.
    if canFilter {
      Button {
        isolatedKind = isolatedKind == entry.kind ? nil : entry.kind
      } label: {
        legendRowContent(for: entry, readout: readout)
      }
      .buttonStyle(.plain)
      .animation(.snappy(duration: 0.2), value: isolatedKind)
      .accessibilityLabel(Text(label(for: entry.kind)))
      .accessibilityHint(
        Text(
          isolatedKind == entry.kind
            ? String(localized: "Show every finish")
            : String(localized: "Show only this finish")
        )
      )
    } else {
      legendRowContent(for: entry, readout: readout)
        .accessibilityElement(children: .combine)
    }
  }

  func legendRowContent(
    for entry: PriceHistorySection.Series,
    readout: (point: PricePoint, change: PriceChange?)
  ) -> some View {
    let isDimmed = isolatedKind != nil && isolatedKind != entry.kind

    return HStack(alignment: .firstTextBaseline, spacing: 6.0) {
      Circle()
        .fill(color(for: entry.kind))
        .frame(width: 7.0, height: 7.0)

      Text(label(for: entry.kind))
        .font(.caption)
        .foregroundStyle(.secondary)

      Text(readout.point.amount, format: .currency(code: currencyCode))
        .font(.caption)
        .fontWeight(.semibold)
        .monospacedDigit()
        .foregroundStyle(.primary)
        .contentTransition(.numericText())

      Spacer(minLength: 6.0)

      if let change = readout.change {
        Text(changeText(for: change))
          .font(.caption)
          .fontWeight(.medium)
          .monospacedDigit()
          .foregroundStyle(trend(change))
          .contentTransition(.numericText())
      }
    }
    .padding(.horizontal, 6.0)
    .padding(.vertical, 3.0)
    // Only the isolated row is filled, so "one of these is selected" is legible
    // at a glance without adding a checkmark column.
    .background(
      isolatedKind == entry.kind ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear),
      in: RoundedRectangle(cornerRadius: 8.0)
    )
    .opacity(isDimmed ? 0.45 : 1.0)
    .contentShape(RoundedRectangle(cornerRadius: 8.0))
  }

  var currencyCode: String {
    if case let .data(section) = state { section.currency } else { "USD" }
  }
}

// MARK: - Chart

private extension PriceHistoryChartView {
  func chart(for section: PriceHistorySection) -> some View {
    let drawn = displayedSeries(of: section)
    let extents = extents(of: section)
    let domain = yDomain(for: extents.price)
    let fractionDigits = extents.price.upperBound < 10 ? 2 : 0

    return Chart {
      ForEach(section.releases) { release in
        RuleMark(x: .value("Release", release.date))
          .foregroundStyle(.secondary.opacity(0.3))
          .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
      }

      ForEach(drawn) { series in
        ForEach(series.points) { point in
          LineMark(
            x: .value("Date", point.date),
            y: .value("Price", point.amount.doubleValue),
            series: .value("Finish", series.id)
          )
          .interpolationMethod(.monotone)
          .foregroundStyle(color(for: series.kind))

          // A gradient under a single line reads as "this is the price"; under
          // two overlapping lines it reads as mud.
          if drawn.count == 1 {
            AreaMark(
              x: .value("Date", point.date),
              // Explicit floor. `AreaMark(x:y:)` fills down to the *value* zero,
              // not to the bottom of the scale — with a domain of 8.9...9.9 that
              // shape runs hundreds of points below the plot, which is where
              // both "Invalid frame dimension (negative or non-finite)" and the
              // fill bleeding down the whole screen came from.
              yStart: .value("Floor", domain.lowerBound),
              yEnd: .value("Price", point.amount.doubleValue)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(
              .linearGradient(
                colors: [
                  color(for: series.kind).opacity(0.26),
                  color(for: series.kind).opacity(0.0),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
          }
        }
      }
      // The scrub's own rule and dots are drawn over the chart, not as marks
      // inside it. See `focusOverlay`.
    }
    .chartLegend(.hidden)
    // Explicit domains. `.automatic(includesZero: false)` collapses to zero span
    // on a flat series — a bulk card pinned at $0.02 for a month — and a
    // zero-height scale is the other source of "Invalid frame dimension".
    .chartYScale(domain: domain)
    .chartXScale(domain: extents.date)
    .chartYAxis {
      AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
        AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
        AxisValueLabel {
          if let amount = value.as(Double.self) {
            Text(amount, format: .number.precision(.fractionLength(fractionDigits)))
              .font(.caption2)
          }
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic(desiredCount: 4)) { _ in
        AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
        AxisValueLabel(format: axisDateStyle(forDays: spanInDays(of: extents.date)))
      }
    }
    .chartOverlay { proxy in
      // `plotFrame` is an anchor, and resolving an anchor needs a geometry
      // proxy — but it does not need a `GeometryReader`, which would insert a
      // layout container into the overlay. `onGeometryChange` hands over the
      // same proxy and changes nothing about how the overlay is laid out.
      // The anchor is pulled out here rather than inside the closure: it is
      // `Sendable` where `ChartProxy` is not, and the geometry closure is
      // `@Sendable`.
      let plotAnchor = proxy.plotFrame

      ZStack(alignment: .topLeading) {
        Color.clear
          .onGeometryChange(for: CGRect.self) { geometry in
            plotAnchor.map { geometry[$0] } ?? .zero
          } action: { plot = $0 }

        if plot.width > 0 {
          releaseOverlay(section.releases, proxy: proxy, plot: plot)
            // Decoration only — every touch on the plot belongs to the reader
            // stacked above it.
            .allowsHitTesting(false)

          focusOverlay(section, proxy: proxy, plot: plot)
            .allowsHitTesting(false)

          ChartTouchReader { positions in
            updateInteraction(positions, proxy: proxy, plot: plot)
          }
        }
      }
    }
  }

  /// Where the reader is scrubbing: a rule down the plot and a dot on each line.
  ///
  /// Drawn over the chart rather than as `RuleMark` and `PointMark` inside it.
  /// Swift Charts strands a point's layer where it last drew: letting go of a
  /// scrub cleared the legend and the rule, and left both dots sitting where
  /// the finger had been, whatever the marks were told afterwards. The release
  /// symbols along the top are positioned off the proxy for their own reasons,
  /// and this uses the same route — plain SwiftUI, which cannot go stale.
  ///
  /// The dot matches the `symbolSize(56)` it replaces: that is an area in
  /// square points, so the diameter is `2 * sqrt(56 / π)`.
  @ViewBuilder
  func focusOverlay(
    _ section: PriceHistorySection,
    proxy: ChartProxy,
    plot: CGRect
  ) -> some View {
    if let focusDate, let focusX = proxy.position(forX: focusDate), focusX.isFinite {
      ZStack(alignment: .topLeading) {
        Rectangle()
          .fill(.secondary.opacity(0.45))
          .frame(width: 1.0, height: plot.height)
          .position(x: plot.minX + focusX, y: plot.midY)

        ForEach(displayedSeries(of: section)) { series in
          if let point = nearestPoint(in: series, to: focusDate),
             let x = proxy.position(forX: point.date),
             let y = proxy.position(forY: point.amount.doubleValue),
             x.isFinite, y.isFinite {
            Circle()
              .fill(color(for: series.kind))
              .frame(width: 8.44, height: 8.44)
              .position(x: plot.minX + x, y: plot.minY + y)
          }
        }
      }
    }
  }

  /// Height of the strip at the top of the plot that the release symbols sit in.
  /// Sized for an expanded symbol, so growing one cannot reach past the top of
  /// the chart and be cut off.
  var releaseBandHeight: CGFloat { 38.0 }

  /// Set symbols along the top of the plot, in the manner of MTGGoldfish's price
  /// graphs: a release is the single most common reason a line steps.
  ///
  /// A marker grows and names itself when the reader's finger comes near it, so
  /// the resting state stays a row of small symbols instead of a row of labels
  /// that would collide with each other and with the lines.
  func releaseOverlay(
    _ releases: [SetReleaseMarker],
    proxy: ChartProxy,
    plot: CGRect
  ) -> some View {
    let positions = releasePositions(releases, proxy: proxy, plot: plot)
    let focused = focusedReleaseID(among: positions, proxy: proxy, plot: plot)

    return ZStack(alignment: .topLeading) {
      ForEach(positions, id: \.release.id) { entry in
        releaseIcon(entry.release, expanded: entry.release.id == focused)
          .position(x: entry.x, y: plot.minY + releaseBandHeight / 2.0)
          .zIndex(entry.release.id == focused ? 1.0 : 0.0)
      }
    }
    // Keyed on which marker is focused, not on the focus date. The date changes
    // with every pixel the finger moves, and animating on it restarted the
    // label's transition continuously — the name never finished appearing.
    .animation(.snappy(duration: 0.18), value: focused)
  }

  /// Marker x positions, clamped so a release at either end of the window still
  /// draws a whole symbol inside the plot.
  func releasePositions(
    _ releases: [SetReleaseMarker],
    proxy: ChartProxy,
    plot: CGRect
  ) -> [(release: SetReleaseMarker, x: CGFloat)] {
    releases.compactMap { release in
      guard let x = proxy.position(forX: release.date), x.isFinite else { return nil }
      return (release, min(max(plot.minX + x, plot.minX + 16.0), plot.maxX - 16.0))
    }
  }

  /// The marker the reader is pointing at, if any. Measured in points rather than
  /// days so the hit area feels the same however much history the card has.
  func focusedReleaseID(
    among positions: [(release: SetReleaseMarker, x: CGFloat)],
    proxy: ChartProxy,
    plot: CGRect
  ) -> String? {
    guard
      let focusDate,
      let focusX = proxy.position(forX: focusDate),
      focusX.isFinite
    else {
      return nil
    }
    // `position(forX:)` is relative to the plot's origin; the entries are already
    // offset by `plot.minX`, so bring the focus into the same space.
    let absoluteX = plot.minX + focusX
    guard let nearest = positions.min(by: { abs($0.x - absoluteX) < abs($1.x - absoluteX) })
    else {
      return nil
    }
    return abs(nearest.x - absoluteX) <= 22.0 ? nearest.release.id : nil
  }

  /// The set symbol sits on a filled disc so it stays legible where the price
  /// lines run through it.
  func releaseIcon(_ release: SetReleaseMarker, expanded: Bool) -> some View {
    IconLazyImage(release.iconURL, tintColor: expanded ? .primary : .secondary)
      .frame(width: expanded ? 24.0 : 18.0, height: expanded ? 24.0 : 18.0)
      .padding(expanded ? 5.0 : 4.0)
      .background(.background.opacity(0.9), in: Circle())
      .overlay(Circle().strokeBorder(.separator, lineWidth: expanded ? 1.0 : 0.0))
      // The name hangs off the disc as an overlay rather than sitting in a stack
      // with it, so revealing it cannot shift the symbol off the release date.
      .overlay(alignment: .top) {
        Text(release.name)
          .font(.caption2)
          .fontWeight(.medium)
          .lineLimit(1)
          .fixedSize()
          .padding(.horizontal, 6.0)
          .padding(.vertical, 2.0)
          .background(.background.opacity(0.92), in: Capsule())
          .overlay(Capsule().strokeBorder(.separator, lineWidth: 0.5))
          .offset(y: expanded ? 38.0 : 30.0)
          .opacity(expanded ? 1.0 : 0.0)
          .allowsHitTesting(false)
      }
      .accessibilityLabel(Text(release.name))
  }

  func yDomain(for prices: ClosedRange<Double>) -> ClosedRange<Double> {
    let low = prices.lowerBound
    let high = prices.upperBound
    guard low.isFinite, high.isFinite else { return 0.0...1.0 }
    // Generous headroom at the top: the release symbols sit in a band inside the
    // plot, and the lines have to stay clear of them.
    let span = high - low
    let padding = span > 0 ? span * 0.12 : max(abs(high) * 0.1, 0.05)
    let lower = max(0.0, low - padding)
    let upper = high + padding * 2.5
    guard lower.isFinite, upper.isFinite, upper > lower else { return 0.0...1.0 }
    return lower...upper
  }

  /// Whole days the chart covers.
  func spanInDays(of dates: ClosedRange<Date>) -> Int {
    max(1, Int((dates.upperBound.timeIntervalSince(dates.lowerBound) / 86_400).rounded()))
  }

  /// Ticks that suit however much history this particular card has.
  func axisDateStyle(forDays days: Int) -> Date.FormatStyle {
    switch days {
    case ..<10: .dateTime.weekday(.abbreviated)
    case ..<60: .dateTime.month(.abbreviated).day()
    default: .dateTime.month(.abbreviated)
    }
  }

  /// Turns the reader's touch position into a scrub date, or clears it.
  func updateInteraction(_ positions: [CGFloat], proxy: ChartProxy, plot: CGRect) {
    guard plot.width > 0 else { return }

    guard let x = positions.first else {
      if interaction.scrubbedDate != nil { interaction.scrubbedDate = nil }
      return
    }

    let clamped = min(max(x - plot.minX, 0.0), plot.width)
    guard let date = proxy.value(atX: clamped, as: Date.self) else { return }
    interaction.scrubbedDate = date
  }

}

// MARK: - Text

private extension PriceHistoryChartView {
  func changeText(for change: PriceChange) -> String {
    let sign = change.isIncrease ? "+" : ""
    let formatted = change.absolute.formatted(.currency(code: currencyCode))
    guard let fraction = change.fraction else { return sign + formatted }
    return "\(sign)\(formatted) (\(fraction.formatted(.percent.precision(.fractionLength(0...1)))))"
  }

  /// What the chart covers, in words, derived from the data rather than from a
  /// tab the reader picked. A card released nine days ago says "Past 9 Days";
  /// one that has been in print for years says "Past 3 Months", because that is
  /// all MTGJSON keeps.
  func spanText(for section: PriceHistorySection) -> String {
    if let scrubbedDate = interaction.scrubbedDate,
       let anchor = displayedSeries(of: section).first,
       let point = nearestPoint(in: anchor, to: scrubbedDate) {
      return point.date.formatted(date: .abbreviated, time: .omitted)
    }

    let days = spanInDays(of: extents(of: section).date)
    switch days {
    case ..<14:
      return String(localized: "Past \(days) Days")
    case ..<60:
      let weeks = max(1, Int((Double(days) / 7.0).rounded()))
      return String(localized: "Past \(weeks) Weeks")
    default:
      let months = max(1, Int((Double(days) / 30.0).rounded()))
      return String(localized: "Past \(months) Months")
    }
  }
}

private extension Decimal {
  var doubleValue: Double { (self as NSDecimalNumber).doubleValue }
}
