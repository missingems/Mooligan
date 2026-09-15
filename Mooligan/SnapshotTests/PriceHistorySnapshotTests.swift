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
      )
    )
  }

  private static let groups = PurchaseVendorGroup.make(
    links: PurchaseLinksMapper.makeLinks(
      from: MTGGraphQLPurchaseUrls(
        tcgplayer: "https://mtgjson.com/links/tcg",
        cardKingdom: "https://mtgjson.com/links/ck",
        cardKingdomFoil: "https://mtgjson.com/links/ck-foil",
        cardmarket: "https://mtgjson.com/links/mkm"
      )
    ),
    quotes: [
      .tcgplayer: RetailQuote(currency: "USD", prices: [.normal: 216.70, .foil: 272.04]),
      .cardkingdom: RetailQuote(currency: "USD", prices: [.normal: 219.99, .foil: 279.99]),
      .cardmarket: RetailQuote(currency: "EUR", prices: [.normal: 189.50, .foil: 240.00]),
    ],
    scryfallPrices: Card.Prices()
  )

  private func snapshot<Content: View>(
    _ content: Content,
    height: CGFloat,
    scheme: ColorScheme = .light,
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
    try await Task.sleep(for: .seconds(1.5))

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
    var card = Card.mock()
    card.finishes = [.nonfoil, .foil]
    card.prices = Card.Prices(usd: "216.70", usdFoil: "272.04")
    return card
  }

  private func display(_ state: PriceHistoryState) -> PriceHistoryDisplay {
    PriceHistoryDisplay.make(card: Self.card, state: state, labels: labels)
  }

  private func section(_ state: PriceHistoryState) -> some View {
    VStack(spacing: 0.0) {
      PriceHistoryView(
        display: display(state),
        purchaseDropdown: .loading,
        labels: labels,
        onRetry: {},
        onPurchaseLinksRequested: {}
      )
    }
    .environment(\.priceHistoryPlaceholderAnimates, false)
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
    #expect(heights[0] > PriceHistoryView.chartHeight)
  }

  @Test func chartChromeShouldLandWhereSwiftChartsPlacesValues() async throws {
    let display = display(.data(Self.section))
    let chart = display.chart
    let axis = display.axis
    let dates = [0.0, 0.3, 1.0].map {
      chart.plotDateRange.lowerBound.addingTimeInterval($0 * chart.plotDateRange.upperBound.timeIntervalSince(chart.plotDateRange.lowerBound))
    }
    let prices = [axis.domain.lowerBound, (axis.domain.lowerBound + axis.domain.upperBound) / 2.0, axis.domain.upperBound]
    let probe = ChartProxyProbe()
    let interaction = ChartInteraction()
    let size = CGSize(width: 380.0, height: PriceHistoryView.chartHeight)

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
      .chartXScale(domain: chart.plotDateRange)
      .chartYAxis {
        AxisMarks(position: .trailing, values: axis.ticks) { value in
          AxisValueLabel(anchor: .leading) {
            Text(axis.label(at: value.index)).font(.caption2).monospaced()
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

    let scale = PlotScale(plot: probe.plot, dates: chart.plotDateRange, prices: axis.domain)
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

  @Test func scrubbingOverAReleaseShowsItsTitle() async throws {
    let base = Self.section
    let releases = [
      SetReleaseMarker(id: "EARLY", code: "EAR", name: "Innistrad: Crimson Vow", date: base.dateRange.lowerBound, iconURL: nil),
      SetReleaseMarker(id: "LATE", code: "LAT", name: "Murders at Karlov Manor", date: base.dateRange.upperBound.addingTimeInterval(-12 * 86_400), iconURL: nil),
    ]
    let section = PriceHistorySection(series: base.series, currency: base.currency, releases: releases, buylistQuote: base.buylistQuote)
    let display = display(.data(section))

    for release in releases {
      await SnapshotWindow.acquire()
      defer { SnapshotWindow.release() }

      let interaction = ChartInteraction()
      let size = CGSize(width: Self.width - 32.0, height: PriceHistoryView.chartHeight)
      let chart = PriceHistoryChart(derivedData: display.chart, axis: display.axis, interaction: interaction)
        .frame(width: size.width, height: size.height)
        .padding(16.0)
        .environment(\.priceHistoryPlaceholderAnimates, false)

      let controller = UIHostingController(rootView: chart.background(Color(.systemBackground)).environment(\.colorScheme, .light))
      controller.safeAreaRegions = []
      let scene = try #require(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
      let window = UIWindow(windowScene: scene)
      window.overrideUserInterfaceStyle = .light
      window.frame = CGRect(x: 0.0, y: 0.0, width: Self.width, height: size.height + 32.0)
      window.rootViewController = controller
      window.makeKeyAndVisible()
      controller.view.frame = window.bounds
      try await Task.sleep(for: .seconds(1.0))

      let scale = PlotScale(plot: interaction.plot, dates: display.chart.plotDateRange, prices: display.axis.domain)
      let entry = try #require(ReleaseMarkerLayout(releases: display.chart.releases, scale: scale).entries.first { $0.release.id == release.id })
      interaction.scrubbedDate = scale.date(atX: entry.iconCenter.x)
      interaction.needleX = entry.iconCenter.x
      try await Task.sleep(for: .seconds(1.0))

      assertSnapshot(
        of: controller.view,
        as: .image(drawHierarchyInKeyWindow: true, precision: 0.98, perceptualPrecision: 0.98),
        named: release.id.lowercased()
      )

      window.isHidden = true
      window.rootViewController = nil
    }
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

  @Test func purchaseLinksDropdown() async throws {
    let states: [(String, PurchaseDropdownState)] = [
      ("loaded", .loaded(Self.groups)),
      ("loading", .loading),
      ("failed", .failed),
      ("empty", .loaded([])),
    ]
    for (name, state) in states {
      try await snapshot(
        PriceHistoryPurchaseLinksView(state: state, labels: labels, onRetry: {}, onSelect: { _ in })
          .padding(13.0)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing),
        height: 420.0,
        named: name
      )
    }
  }
}
