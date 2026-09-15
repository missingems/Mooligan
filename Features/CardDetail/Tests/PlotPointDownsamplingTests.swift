@testable import CardDetail
import Foundation
import Networking
import Testing

struct PlotPointDownsamplingTests {
  private let day: TimeInterval = 86_400
  private let start = Date(timeIntervalSince1970: 1_788_000_000)

  private func points(_ values: [Double]) -> [ChartDerivedData.PlotPoint] {
    values.enumerated().map { offset, value in
      ChartDerivedData.PlotPoint(date: start.addingTimeInterval(Double(offset) * day), value: value)
    }
  }

  private func series(_ kind: PriceSeriesKind, days count: Int) -> PriceHistorySection.Series {
    let prices = (0..<count).map { offset in
      PricePoint(date: start.addingTimeInterval(Double(offset) * day), amount: Decimal(offset + 1))
    }
    return PriceHistorySection.Series(kind: kind, points: prices)!
  }

  @Test func withinTheLimit_everyPointShouldStay() {
    let original = points((0..<50).map(Double.init))

    #expect(original.downsampled(to: 60) == original)
  }

  @Test func overTheLimit_shouldKeepTheEndsAndStayInOrder() {
    let original = points((0..<200).map { sin(Double($0) / 9.0) })
    let sampled = original.downsampled(to: 60)

    #expect(sampled.count == 60)
    #expect(sampled.first == original.first)
    #expect(sampled.last == original.last)
    #expect(zip(sampled, sampled.dropFirst()).allSatisfy { $0.date < $1.date })
  }

  @Test func aOneDaySpikeShouldSurviveTheThinning() {
    var values = Array(repeating: 10.0, count: 200)
    values[117] = 40.0
    let sampled = points(values).downsampled(to: 40)

    #expect(sampled.contains { $0.value == 40.0 })
  }

  @Test func theChartShouldDrawAtMost180PointsAcrossEveryFinish() {
    let section = PriceHistorySection(
      series: [series(.normal, days: 91), series(.foil, days: 91), series(.etched, days: 91)],
      currency: "USD"
    )
    let derived = ChartDerivedData(section: section)

    #expect(derived.plotSeries.map(\.points.count).reduce(0, +) <= ChartDerivedData.maxPlottedPoints)
    #expect(derived.series.map(\.points.count) == [91, 91, 91])
  }

  @Test func aSingleFinishShouldKeepItsWholeWindow() {
    let derived = ChartDerivedData(section: PriceHistorySection(series: [series(.normal, days: 91)], currency: "USD"))

    #expect(derived.plotSeries[0].points.count == 91)
  }
}
