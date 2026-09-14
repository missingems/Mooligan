@testable import CardDetail
import Foundation
import Networking
import Testing

struct PriceReadoutTests {
  private let day: TimeInterval = 86_400
  private let start = Date(timeIntervalSince1970: 1_788_000_000)

  private func decimal(_ value: String) -> Decimal {
    Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))!
  }

  private func series(_ amounts: [String], kind: PriceSeriesKind = .normal) -> PriceHistorySection.Series {
    let points = amounts.enumerated().map { offset, amount in
      PricePoint(date: start.addingTimeInterval(Double(offset) * day), amount: decimal(amount))
    }
    return PriceHistorySection.Series(kind: kind, points: points)!
  }

  @Test func latestReadout_shouldCompareTheLastTwoObservations() {
    let readout = series(["1.00", "5.00", "4.00"]).latestReadout

    #expect(readout?.point.amount == decimal("4.00"))
    #expect(readout?.change?.start.amount == decimal("5.00"))
    #expect(readout?.change?.absolute == decimal("-1.00"))
    #expect(readout?.change?.isDecrease == true)
    #expect(readout?.isScrubbing == false)
  }

  @Test func dayChange_atTheFirstObservation_shouldBeNil() {
    #expect(series(["1.00", "2.00"]).dayChange(endingAt: 0) == nil)
  }

  @Test func dayChange_outsideTheSeries_shouldBeNil() {
    #expect(series(["1.00", "2.00"]).dayChange(endingAt: 9) == nil)
  }

  @Test func indexOfPoint_shouldSnapToTheNearestObservation() {
    let subject = series(["1.00", "2.00", "3.00", "4.00"])

    #expect(subject.indexOfPoint(nearest: start.addingTimeInterval(-day)) == 0)
    #expect(subject.indexOfPoint(nearest: start.addingTimeInterval(2.4 * day)) == 2)
    #expect(subject.indexOfPoint(nearest: start.addingTimeInterval(2.6 * day)) == 3)
    #expect(subject.indexOfPoint(nearest: start.addingTimeInterval(100 * day)) == 3)
  }

  @Test func whenScrubbing_theReadoutShouldFollowTheNeedle() {
    let subject = series(["1.00", "2.00", "3.00", "4.00"])
    let interaction = ChartInteraction()

    interaction.scrubbedDate = start.addingTimeInterval(2 * day)
    let readout = interaction.pointIndex(for: subject).flatMap { subject.readout(at: $0, isScrubbing: true) }

    #expect(readout?.point.amount == decimal("3.00"))
    #expect(readout?.change?.start.amount == decimal("2.00"))
    #expect(readout?.change?.absolute == decimal("1.00"))
    #expect(readout?.isScrubbing == true)
  }

  @Test func whenTheScrubEnds_theReadoutShouldReturnToTheLatest() {
    let subject = series(["1.00", "2.00", "3.00", "4.00"])
    let interaction = ChartInteraction()

    interaction.scrubbedDate = start
    #expect(interaction.pointIndex(for: subject).map { subject.points[$0].amount } == decimal("1.00"))

    interaction.scrubbedDate = nil
    #expect(interaction.pointIndex(for: subject) == subject.points.indices.last)
    #expect(subject.latestReadout?.point.amount == decimal("4.00"))
    #expect(subject.latestReadout?.isScrubbing == false)
  }

  @Test func whenScrubbingAcrossContiguousDays_theCachedLookupShouldStayCorrect() {
    let subject = series((0..<30).map { "\($0 + 1).00" })
    let interaction = ChartInteraction()

    for index in 0..<30 {
      interaction.scrubbedDate = subject.points[index].date
      #expect(interaction.pointIndex(for: subject) == index)
    }

    for index in (0..<30).reversed() {
      interaction.scrubbedDate = subject.points[index].date
      #expect(interaction.pointIndex(for: subject) == index)
    }

    interaction.scrubbedDate = subject.points[27].date
    #expect(interaction.pointIndex(for: subject) == 27)
  }

  @Test func anchorSeries_shouldBeTheFirstFinishDrawn() {
    let section = PriceHistorySection(
      series: [series(["1.00", "2.00"]), series(["8.00", "9.00"], kind: .foil)],
      currency: "USD"
    )

    #expect(ChartDerivedData(section: section).anchorSeries?.kind == .normal)
  }

  @Test func series_shouldBeOrderedRegularFoilEtched() {
    let section = PriceHistorySection(
      series: [
        series(["4.00", "5.00"], kind: .etched),
        series(["8.00", "9.00"], kind: .foil),
        series(["1.00", "2.00"]),
      ],
      currency: "USD"
    )

    #expect(
      ChartDerivedData(section: section)
        .series.map(\.kind) == [.normal, .foil, .etched]
    )
  }
}
