@testable import CardDetail
import Charts
import Networking
import ScryfallKit
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

@MainActor
private final class ChartProxyProbe {
  var plot: CGRect = .zero
  var xs: [CGFloat?] = []
  var ys: [CGFloat?] = []
  var quarterDate: Date?
}

@MainActor
@Suite(.serialized)
struct PriceHistorySnapshotTests {
  private static let width: CGFloat = 402.0
  private static let end = Date(timeIntervalSince1970: 1_780_272_000)
  private let labels = PriceHistoryLabels()

  private static func series(_ kind: PriceSeriesKind, base: Double, swing: Double) -> PriceHistorySection.Series? {
    let points = (0..<60).map { offset in
      let value = base + sin(Double(offset) / 6.0) * swing + Double(offset) * swing * 0.02
      return PricePoint(
        date: end.addingTimeInterval(-Double(59 - offset) * 86_400),
        amount: Decimal((value * 100).rounded() / 100)
      )
    }
    return PriceHistorySection.Series(kind: kind, points: points)
  }

  /// Two finishes over two months, a buylist, and two set releases: one mid-plot and one on the
  /// last charted day, whose icon hangs half past the plot's edge. Without an icon URL the icon is
  /// the static placeholder, so the render is deterministic.
  private static var section: PriceHistorySection {
    PriceHistorySection(
      series: [
        series(.normal, base: 212.0, swing: 6.0),
        series(.foil, base: 265.0, swing: 9.0),
      ].compactMap { $0 },
      currency: "USD",
      buylistQuote: BuylistQuote(
        provider: .cardkingdom,
        retail: [.normal: 219.99, .foil: 279.99],
        buylist: [.normal: 150.0, .foil: 180.0]
      ),
      releases: [
        SetReleaseMarker(id: "mid", code: "mid", name: "Mid Set", date: end.addingTimeInterval(-40 * 86_400), iconURL: nil),
        SetReleaseMarker(id: "new", code: "new", name: "New Set", date: end, iconURL: nil),
      ]
    )
  }

  private func snapshot<Content: View>(
    _ content: Content,
    height: CGFloat,
    scheme: ColorScheme = .light,
    settle: Duration = .seconds(1.5),
    named name: String,
    testName: String = #function
  ) async throws {
    await SnapshotWindow.acquire()
    defer { SnapshotWindow.release() }

    let controller = UIHostingController(
      rootView: content
        .frame(width: Self.width, height: height, alignment: .top)
        .background(Color(.systemBackground))
        .environment(\.colorScheme, scheme)
    )
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    window.frame = CGRect(x: 0.0, y: 0.0, width: Self.width, height: height)
    window.overrideUserInterfaceStyle = scheme == .dark ? .dark : .light
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.view.frame = window.bounds
    try await Task.sleep(for: settle)

    assertSnapshot(
      of: controller.view,
      as: .image(drawHierarchyInKeyWindow: true, precision: 0.98, perceptualPrecision: 0.98),
      named: name,
      testName: testName
    )

    window.isHidden = true
    window.rootViewController = nil
  }

  private static var card: Card {
    var card = Card.mock(name: "Test Card")
    card.finishes = [.nonfoil, .foil]
    card.prices = Card.Prices(usd: "216.70", usdFoil: "272.04")
    return card
  }

  private func display(_ state: PriceHistoryState, card: Card = Self.card) -> PriceHistoryDisplay {
    PriceHistoryDisplay.make(card: card, state: state, labels: labels)
  }

  private func section(_ state: PriceHistoryState, card: Card = Self.card) -> some View {
    VStack(spacing: 0.0) {
      PriceHistoryView(
        display: display(state, card: card),
        labels: labels,
        onRetry: {}
      )
    }
  }


  @Test func loadedSection() async throws {
    for scheme in [ColorScheme.light, .dark] {
      try await snapshot(
        section(.data(Self.section)),
        height: 540.0,
        scheme: scheme,
        named: scheme == .dark ? "dark" : "light"
      )
    }
  }

  @Test func loadingUnavailableAndFailedSections() async throws {
    let states: [(String, PriceHistoryState)] = [
      ("loading", .loading),
      ("unavailable", .unavailable),
      ("failed", .failed),
    ]
    for (name, state) in states {
      try await snapshot(section(state), height: 540.0, named: name)
    }
  }

  @Test func everyStateShouldBeTheSameHeightSoScrollingNeverJumps() {
    let states: [PriceHistoryState] = [.loading, .unavailable, .failed, .data(Self.section)]
    let heights = states.map { state in
      let controller = UIHostingController(rootView: section(state))
      return controller.sizeThatFits(in: CGSize(width: Self.width, height: .greatestFiniteMagnitude)).height
    }

    #expect(heights.allSatisfy { abs($0 - heights[0]) < 0.5 }, "heights: \(heights)")
    #expect(heights[0] > 233.0)
  }

  @Test func chartChromeShouldLandWhereSwiftChartsPlacesValues() async throws {
    let display = display(.data(Self.section))
    let chart = display.chart
    let axis = display.axis
    let dates = [0.0, 0.3, 1.0].map {
      chart.dateRange.lowerBound.addingTimeInterval($0 * chart.dateRange.upperBound.timeIntervalSince(chart.dateRange.lowerBound))
    }
    let prices = [axis.domain.lowerBound, (axis.domain.lowerBound + axis.domain.upperBound) / 2.0, axis.domain.upperBound]
    let probe = ChartProxyProbe()
    let interaction = ChartInteraction()
    let size = CGSize(width: 380.0, height: 233.0)

    let content = VStack(spacing: 0.0) {
      PriceHistoryChart(derivedData: chart, axis: axis, interaction: interaction)
        .frame(width: size.width, height: size.height)

      Chart(chart.plotSeries) { series in
        ForEach(series.points) { point in
          LineMark(x: .value("Date", point.date), y: .value("Price", point.value), series: .value("ID", series.id))
        }
      }
      .chartLegend(.hidden)
      .chartYScale(domain: axis.domain)
      .chartXScale(domain: chart.dateRange)
      .chartYAxis {
        AxisMarks(position: .trailing, values: axis.ticks) { value in
          AxisValueLabel(anchor: .leading) {
            Text(axis.label(at: value.index)).font(.caption2).fontDesign(.rounded)
          }
        }
      }
      .chartXAxis {
        AxisMarks(values: .automatic(desiredCount: 3)) { value in
          AxisValueLabel(anchor: .top) {
            if let date = value.as(Date.self) {
              Text(date, format: PriceChartStyle.axisDateStyle(forDays: chart.spanInDays)).font(.caption2)
            }
          }
        }
      }
      .chartOverlay { proxy in
        let anchor = proxy.plotFrame
        Color.clear.onGeometryChange(for: CGRect.self) { geometry in
          anchor.map { geometry[$0] } ?? .zero
        } action: { plot in
          probe.plot = plot
          probe.xs = dates.map { date in proxy.position(forX: date).map { plot.minX + $0 } }
          probe.ys = prices.map { price in proxy.position(forY: price).map { plot.minY + $0 } }
          probe.quarterDate = proxy.value(atX: plot.width * 0.25, as: Date.self)
        }
      }
      .frame(width: size.width, height: size.height)
    }

    await SnapshotWindow.acquire()
    defer { SnapshotWindow.release() }

    let controller = UIHostingController(rootView: content.background(Color(.systemBackground)))
    let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    window.frame = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height * 2.0)
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.view.frame = window.bounds
    defer {
      window.isHidden = true
      window.rootViewController = nil
    }
    try await Task.sleep(for: .seconds(1.0))

    let tolerance = 0.5
    #expect(probe.plot.width > 0.0)
    #expect(abs(interaction.plot.minX - probe.plot.minX) < tolerance, "measured \(interaction.plot) proxy \(probe.plot)")
    #expect(abs(interaction.plot.minY - probe.plot.minY) < tolerance, "measured \(interaction.plot) proxy \(probe.plot)")
    #expect(abs(interaction.plot.width - probe.plot.width) < tolerance, "measured \(interaction.plot) proxy \(probe.plot)")
    #expect(abs(interaction.plot.height - probe.plot.height) < tolerance, "measured \(interaction.plot) proxy \(probe.plot)")

    let scale = PlotScale(plot: probe.plot, dates: chart.dateRange, prices: axis.domain)
    for (date, expected) in zip(dates, probe.xs) {
      let x = try #require(scale.x(for: date))
      #expect(abs(x - (try #require(expected))) < tolerance, "x for \(date): \(x) vs proxy \(String(describing: expected))")
    }
    for (price, expected) in zip(prices, probe.ys) {
      let y = try #require(scale.y(for: price))
      #expect(abs(y - (try #require(expected))) < tolerance, "y for \(price): \(y) vs proxy \(String(describing: expected))")
    }
    let quarter = try #require(scale.date(atX: probe.plot.minX + probe.plot.width * 0.25))
    #expect(abs(quarter.timeIntervalSince(try #require(probe.quarterDate))) < 3_600.0)
  }

  /// A sub-dollar card's axis, where rounding once left the top grid line without its price.
  @Test func subDollarAxisShouldLabelEveryGridLine() async throws {
    let axis = PriceChartStyle.priceAxis(for: 0.333...0.4995).labeled(currencyCode: "USD")
    try await snapshot(
      PriceHistoryChart(derivedData: ChartDerivedData(), axis: axis, interaction: ChartInteraction())
        .frame(height: 233.0)
        .padding(),
      height: 233.0 + 32.0,
      named: "fixed"
    )
  }

  /// A card printed in regular, foil and etched foil puts its four items two to a row.
  @Test func fourItemsShouldSitTwoToARow() async throws {
    var card = Self.card
    card.finishes = [.nonfoil, .foil, .etched]
    card.prices = Card.Prices(usd: "216.70", usdFoil: "272.04", usdEtched: "301.15")
    try await snapshot(section(.data(Self.section), card: card), height: 540.0, named: "loaded")
  }

  /// With no finishes and no prices, regular, foil and buy back still show, as greyed-out dashes.
  @Test func withoutPricesTheItemsShouldBeGreyedOutDashes() async throws {
    var card = Self.card
    card.finishes = []
    card.prices = Card.Prices()
    try await snapshot(section(.unavailable, card: card), height: 540.0, named: "unavailable")
  }

  /// Tapping buy back opens a sheet with the vendor, its price for each finish and a link to sell.
  @Test func buyBackSheet() async throws {
    let display = display(.data(Self.section))
    try await snapshot(
      PriceHistoryBuyBackSheet(buyBack: display.buyBack, labels: labels),
      height: 360.0,
      named: "sheet"
    )
  }

  /// Each stage of the scrub choreography: the copies over the toolbar's capsules, slid into one,
  /// balled up at the needle's foot, and absorbed with the readout open at the tip. The last is
  /// taken twice, mid-plot and at the plot's end, where the screen's edge stops the readout.
  @Test func scrubbingShouldCarryThePricesUpTheNeedle() async throws {
    let display = display(.data(Self.section))
    let range = display.chart.dateRange
    let stages: [(String, ScrubReadoutPhase, Double)] = [
      ("start", .start, 0.6),
      ("gathered", .gathered, 0.6),
      ("balled", .balled, 0.6),
      ("expanded", .expanded, 0.6),
      ("edge", .expanded, 0.98),
    ]
    for (name, phase, fraction) in stages {
      let interaction = ChartInteraction()
      interaction.scrubbedDate = range.lowerBound.addingTimeInterval(range.upperBound.timeIntervalSince(range.lowerBound) * fraction)
      try await snapshot(
        VStack(spacing: 0.0) {
          PriceHistoryView(display: display, labels: labels, onRetry: {}, interaction: interaction, scrubPhase: phase)
        },
        height: 540.0,
        named: name
      )
    }
  }

  /// Scrubbing a card whose regular finish has no price: only the foil capsule gets a copy and only
  /// foil is read out; the regular dash is left alone.
  @Test func scrubbingShouldOnlyCarryTheFinishesWithAPrice() async throws {
    var card = Self.card
    card.prices = Card.Prices(usd: nil, usdFoil: "272.04")
    let foilOnly = PriceHistorySection(
      series: [Self.series(.foil, base: 265.0, swing: 9.0)].compactMap { $0 },
      currency: "USD"
    )
    let display = display(.data(foilOnly), card: card)
    let range = display.chart.dateRange
    for (name, phase) in [("start", ScrubReadoutPhase.start), ("expanded", .expanded)] {
      let interaction = ChartInteraction()
      interaction.scrubbedDate = range.lowerBound.addingTimeInterval(range.upperBound.timeIntervalSince(range.lowerBound) * 0.6)
      try await snapshot(
        VStack(spacing: 0.0) {
          PriceHistoryView(display: display, labels: labels, onRetry: {}, interaction: interaction, scrubPhase: phase)
        },
        height: 540.0,
        named: name
      )
    }
  }

  /// Without any history from the feed, the card's Scryfall prices still draw: a flat week each.
  @Test func withoutHistoryTheScryfallPricesShouldDrawAFlatWeek() async throws {
    let state = PriceHistorySection.makeState(card: Self.card, history: nil, today: Self.end)
    try await snapshot(section(state), height: 540.0, named: "flat")
  }

  @Test func emptyChartMessages() async throws {
    for reason in [PriceHistoryEmptyMessage.Reason.unavailable, .failed] {
      try await snapshot(
        PriceHistoryEmptyMessage(reason: reason, labels: labels, onRetry: {})
          .frame(maxWidth: .infinity, maxHeight: .infinity),
        height: 200.0,
        named: reason == .failed ? "failed" : "unavailable"
      )
    }
  }

}
