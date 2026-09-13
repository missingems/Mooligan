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
}
