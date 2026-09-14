@testable import CardDetail
import CoreGraphics
import Foundation
import Testing

struct PriceHistoryChartChromeTests {
  @Test func dotRowsShouldLandOnEveryPriceTick() {
    let layout = DotMatrixLayout(
      plot: CGRect(x: 0.0, y: 0.0, width: 300.0, height: 200.0),
      tickRows: [200.0, 150.0, 100.0, 50.0, 0.0]
    )
    let rows = Set(layout.dots().map(\.y))

    for tick in layout.tickRows {
      #expect(rows.contains { abs($0 - tick) < 0.5 })
    }
  }

  @Test func dotsShouldBeEvenlySpacedAcrossAndDown() {
    let layout = DotMatrixLayout(plot: CGRect(x: 0.0, y: 0.0, width: 300.0, height: 200.0), tickRows: [0.0, 50.0, 100.0])
    let dots = layout.dots()
    let xs = Set(dots.map(\.x)).sorted()
    let ys = Set(dots.map(\.y)).sorted()

    #expect(abs((xs[1] - xs[0]) - layout.spacing) < 0.001)
    #expect(abs((ys[1] - ys[0]) - layout.spacing) < 0.001)
    #expect(abs((xs.last ?? 0.0) - 300.0) < 0.001)
  }

  @Test func dotSpacingShouldSubdivideTheTickGapNearTheTarget() {
    let layout = DotMatrixLayout(plot: CGRect(x: 0.0, y: 0.0, width: 300.0, height: 200.0), tickRows: [0.0, 50.0])

    #expect(layout.spacing == 10.0)
  }

  @Test func dotsShouldStayInsideThePlot() {
    let plot = CGRect(x: 12.0, y: 8.0, width: 280.0, height: 190.0)
    let dots = DotMatrixLayout(plot: plot, tickRows: [30.0, 90.0, 150.0]).dots()

    #expect(dots.isEmpty == false)
    #expect(dots.allSatisfy { plot.insetBy(dx: -0.5, dy: -0.5).contains($0) })
  }

  @Test func anUnmeasuredPlotShouldDrawNothing() {
    #expect(DotMatrixLayout(plot: .zero, tickRows: [1.0, 2.0]).dots().isEmpty)
  }

  @Test func plotScaleShouldMapDomainEndsOntoPlotEdges() throws {
    let start = Date(timeIntervalSince1970: 1_780_000_000)
    let end = start.addingTimeInterval(90 * 86_400)
    let scale = PlotScale(plot: CGRect(x: 10.0, y: 20.0, width: 300.0, height: 200.0), dates: start...end, prices: 50.0...150.0)

    #expect(try #require(scale.x(for: start)) == 10.0)
    #expect(try #require(scale.x(for: end)) == 310.0)
    #expect(abs(try #require(scale.x(for: start.addingTimeInterval(45 * 86_400))) - 160.0) < 0.001)
    #expect(try #require(scale.y(for: 50.0)) == 220.0)
    #expect(try #require(scale.y(for: 150.0)) == 20.0)
    #expect(abs(try #require(scale.y(for: 100.0)) - 120.0) < 0.001)
  }

  @Test func plotScaleShouldInvertAndClampScrubPositions() throws {
    let start = Date(timeIntervalSince1970: 1_780_000_000)
    let end = start.addingTimeInterval(60 * 86_400)
    let scale = PlotScale(plot: CGRect(x: 8.0, y: 0.0, width: 240.0, height: 180.0), dates: start...end, prices: 0.0...1.0)
    let middle = start.addingTimeInterval(20 * 86_400)

    let x = try #require(scale.x(for: middle))
    #expect(abs(try #require(scale.date(atX: x)).timeIntervalSince(middle)) < 1.0)
    #expect(try #require(scale.date(atX: -50.0)) == start)
    #expect(try #require(scale.date(atX: 1_000.0)) == end)
  }

  @Test func anUnmeasuredPlotScaleShouldPlaceNothing() {
    let now = Date(timeIntervalSince1970: 1_780_000_000)
    let scale = PlotScale(plot: .zero, dates: now...now.addingTimeInterval(86_400), prices: 0.0...1.0)

    #expect(scale.isMeasured == false)
    #expect(scale.x(for: now) == nil)
    #expect(scale.y(for: 0.5) == nil)
    #expect(scale.date(atX: 0.0) == nil)
  }

  @Test func scrubbingShouldNeedAStillPressFirst() {
    let rule = ScrubPressRule.standard
    let origin = CGPoint(x: 100.0, y: 100.0)

    #expect(rule.minimumPressDuration >= 0.25)
    #expect(rule.hasDrifted(from: origin, to: CGPoint(x: 106.0, y: 106.0)) == false)
    #expect(rule.hasDrifted(from: origin, to: CGPoint(x: 115.0, y: 100.0)))
    #expect(rule.hasDrifted(from: origin, to: CGPoint(x: 100.0, y: 112.0)))
  }
}
