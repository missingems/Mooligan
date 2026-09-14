@testable import CardDetail
import Foundation
import SwiftUI
import Networking
import Testing

struct PriceChartStyleTests {
  private func decimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
  }

  private func change(from: String, to: String) -> PriceChange {
    PriceChange(
      start: PricePoint(date: Date(timeIntervalSince1970: 0), amount: decimal(from)),
      end: PricePoint(date: Date(timeIntervalSince1970: 86_400), amount: decimal(to))
    )
  }

  @Test func shouldPointUpAndDownOnRealMoves() {
    #expect(PriceChartStyle.direction(for: change(from: "10.00", to: "11.00")) == .up)
    #expect(PriceChartStyle.direction(for: change(from: "10.00", to: "9.00")) == .down)
  }

  @Test func whenAMoveRoundsAwayAtOneDecimal_shouldReadFlat() {
    let tiny = change(from: "10000.00", to: "9996.00")

    #expect(PriceChartStyle.changeText(for: tiny) == 0.0004.formatted(.percent.precision(.fractionLength(1))))
    #expect(PriceChartStyle.direction(for: tiny) == .flat)
    #expect(PriceChartStyle.symbol(for: .flat) == "arrow.up")
    #expect(PriceChartStyle.tint(for: .flat) == .gray)
    #expect(PriceChartStyle.pillForeground(for: .flat, in: .dark) == Color(.secondaryLabel))
  }

  @Test func whenAMoveSurvivesAtOneDecimal_shouldPointDown() {
    let small = change(from: "10000.00", to: "9990.00")

    #expect(PriceChartStyle.direction(for: small) == .down)
    #expect(PriceChartStyle.symbol(for: .down) == "arrow.down")
  }

  @Test func whenNothingMoved_shouldReadFlat() {
    #expect(PriceChartStyle.direction(for: change(from: "10.00", to: "10.00")) == .flat)
    #expect(PriceChartStyle.direction(for: nil) == .flat)
    #expect(PriceChartStyle.changeText(for: nil) == PriceChartStyle.flatChangeText)
  }

  @Test func shouldTintMovesWithSystemGreenAndRed() {
    #expect(PriceChartStyle.tint(for: .up) == .green)
    #expect(PriceChartStyle.tint(for: .down) == .red)
    #expect(PriceChartStyle.pillForeground(for: .up, in: .dark) == .green)
    #expect(PriceChartStyle.pillForeground(for: .up, in: .light) != .green)
  }

  @Test func spanTextShouldRoundToTheNearestUnit() {
    let end = Date(timeIntervalSince1970: 1_788_000_000)
    func span(_ days: Double) -> String {
      PriceChartStyle.spanText(of: end.addingTimeInterval(-days * 86_400)...end)
    }

    #expect(span(90) == String(localized: "Past 3 Months"))
    #expect(span(21) == String(localized: "Past 3 Weeks"))
    #expect(span(3) == String(localized: "Past 3 Days"))
  }

  @Test func shouldReportTheMagnitudeUnsigned() {
    #expect(PriceChartStyle.changeText(for: change(from: "10.00", to: "9.00"))
      == PriceChartStyle.changeText(for: change(from: "10.00", to: "11.00")))
  }

  @Test func statWindowShouldBucketTheSpan() {
    #expect(PriceChartStyle.statWindow(forSpanDays: 90).label == "3M")
    #expect(PriceChartStyle.statWindow(forSpanDays: 89).label == "3M")
    #expect(PriceChartStyle.statWindow(forSpanDays: 75).label == "3M")
    #expect(PriceChartStyle.statWindow(forSpanDays: 60).label == "1M")
    #expect(PriceChartStyle.statWindow(forSpanDays: 28).label == "1M")
    #expect(PriceChartStyle.statWindow(forSpanDays: 27).label == "1W")
    #expect(PriceChartStyle.statWindow(forSpanDays: 7).label == "1W")
    #expect(PriceChartStyle.statWindow(forSpanDays: 3).label == "3D")
    #expect(PriceChartStyle.statWindow(forSpanDays: 3).days == nil)
  }

  @Test func priceAxisShouldStepInRoundNumbersWithAStepOfRoomBelowTheLow() {
    let axis = PriceChartStyle.priceAxis(for: 20.23...62.0)

    #expect(axis.ticks == [0.0, 20.0, 40.0, 60.0, 80.0])
    #expect(axis.domain == 0.0...80.0)
    #expect(axis.fractionDigits == 0)
  }

  @Test func priceAxisShouldKeepAHighPricedCardAwayFromZero() {
    let axis = PriceChartStyle.priceAxis(for: 200.0...210.0)

    #expect(axis.ticks == [190.0, 200.0, 210.0, 220.0])
    #expect(axis.domain.lowerBound > 0.0)
  }

  @Test func priceAxisShouldLeaveAtLeastHalfAStepAboveAndBelowTheData() {
    for range in [20.23...41.3, 3.1...4.9, 0.12...0.45, 980.0...1_450.0] {
      let axis = PriceChartStyle.priceAxis(for: range)
      let step = axis.ticks[1] - axis.ticks[0]

      #expect(axis.domain.upperBound - range.upperBound >= step * 0.5 - 0.000_1)
      #expect(range.lowerBound - axis.domain.lowerBound >= min(step * 0.5, range.lowerBound) - 0.000_1)
      #expect(axis.ticks.first == axis.domain.lowerBound)
      #expect(axis.ticks.last == axis.domain.upperBound)
    }
  }

  @Test func priceAxisShouldUseCentsOnlyForFractionalSteps() {
    #expect(PriceChartStyle.priceAxis(for: 0.12...0.45).fractionDigits == 2)
    #expect(PriceChartStyle.priceAxis(for: 20.23...41.3).fractionDigits == 0)
  }

  @Test func priceAxisShouldNeverGoNegativeOrCollapse() {
    #expect(PriceChartStyle.priceAxis(for: 0.1...40.0).domain.lowerBound == 0.0)
    #expect(PriceChartStyle.priceAxis(for: 5.0...5.0).domain.lowerBound < 5.0)
    #expect(PriceChartStyle.priceAxis(for: 5.0...5.0).domain.upperBound > 5.0)
    #expect(PriceChartStyle.priceAxis(for: 0.0...0.0) == PriceChartStyle.fallbackPriceAxis)
  }

  @Test func niceStepShouldRoundUpToOneTwoTwoAndAHalfOrFive() {
    #expect(PriceChartStyle.niceStep(14.0) == 20.0)
    #expect(PriceChartStyle.niceStep(2.2) == 2.5)
    #expect(abs(PriceChartStyle.niceStep(0.07) - 0.1) < 0.000_001)
    #expect(PriceChartStyle.niceStep(300.0) == 500.0)
  }
}
