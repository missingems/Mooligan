@testable import Networking
import Foundation
import Testing

/// Covers the change readout drawn from a price series.
struct PriceChangeTests {
  private let anchor = Date(timeIntervalSince1970: 1_788_000_000)

  private func point(daysBefore days: Int, amount: Decimal) -> PricePoint {
    PricePoint(date: anchor.addingTimeInterval(-Double(days) * 86_400), amount: amount)
  }

  @Test func whenComputingAChange_shouldReportAbsoluteAndFraction() {
    let change = PriceChange(
      start: point(daysBefore: 30, amount: Decimal(string: "2.00")!),
      end: point(daysBefore: 0, amount: Decimal(string: "2.50")!)
    )

    #expect(change.absolute == Decimal(string: "0.50"))
    #expect(change.fraction == 0.25)
    #expect(change.isIncrease)
    #expect(change.isDecrease == false)
  }

  @Test func whenPriceFell_shouldReportANegativeChange() {
    let change = PriceChange(
      start: point(daysBefore: 7, amount: Decimal(string: "4.00")!),
      end: point(daysBefore: 0, amount: Decimal(string: "3.00")!)
    )

    #expect(change.absolute == Decimal(string: "-1.00"))
    #expect(change.fraction == -0.25)
    #expect(change.isDecrease)
  }

  /// MTGJSON reports 0.00 for some listings; a percentage off zero is undefined
  /// and must not surface as infinity in the summary line.
  @Test func whenBaselineIsZero_shouldHaveNoFraction() {
    let change = PriceChange(
      start: point(daysBefore: 7, amount: 0),
      end: point(daysBefore: 0, amount: Decimal(string: "1.00")!)
    )

    #expect(change.absolute == Decimal(string: "1.00"))
    #expect(change.fraction == nil)
  }

  @Test func whenSeriesHasFewerThanTwoPoints_shouldHaveNoChange() {
    #expect([PricePoint]().change == nil)
    #expect([point(daysBefore: 0, amount: 1)].change == nil)
  }

  @Test func whenSeriesHasPoints_shouldMeasureFirstToLast() {
    let series = [
      point(daysBefore: 2, amount: Decimal(string: "1.00")!),
      point(daysBefore: 1, amount: Decimal(string: "5.00")!),
      point(daysBefore: 0, amount: Decimal(string: "2.00")!),
    ]

    let change = try? #require(series.change)
    #expect(change?.absolute == Decimal(string: "1.00"))
  }
}
