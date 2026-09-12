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

  @Test func latestReadout_shouldMeasureFromTheStartOfTheRange() {
    let readout = series(["1.00", "5.00", "4.00"]).latestReadout

    #expect(readout?.point.amount == decimal("4.00"))
    #expect(readout?.change?.start.amount == decimal("1.00"))
    #expect(readout?.change?.absolute == decimal("3.00"))
    #expect(readout?.change?.isIncrease == true)
    #expect(readout?.isScrubbing == false)
  }

  @Test func whenTheRangeNarrows_theChangeShouldFollowItsBaseline() {
    let section = PriceHistorySection(
      series: [series((0..<60).map { "\($0 + 1).00" })],
      currency: "USD"
    )

    let wide = ChartDerivedData(section: section, isolatedKind: nil, range: .quarter)
    let narrow = ChartDerivedData(section: section, isolatedKind: nil, range: .week)

    #expect(wide.anchorSeries?.latestReadout?.change?.start.amount == decimal("1.00"))
    #expect(narrow.anchorSeries?.latestReadout?.change?.start.amount == decimal("53.00"))
    #expect(wide.anchorSeries?.latestReadout?.point.amount == decimal("60.00"))
    #expect(narrow.anchorSeries?.latestReadout?.point.amount == decimal("60.00"))
  }

  @Test func rangeChange_atTheFirstObservation_shouldBeNil() {
    #expect(series(["1.00", "2.00"]).rangeChange(endingAt: 0) == nil)
  }

  @Test func rangeChange_outsideTheSeries_shouldBeNil() {
    #expect(series(["1.00", "2.00"]).rangeChange(endingAt: 9) == nil)
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
    let readout = interaction.readout(for: subject)

    #expect(readout?.point.amount == decimal("3.00"))
    #expect(readout?.change?.start.amount == decimal("1.00"))
    #expect(readout?.change?.absolute == decimal("2.00"))
    #expect(readout?.isScrubbing == true)
  }

  @Test func whenTheScrubEnds_theReadoutShouldReturnToTheLatest() {
    let subject = series(["1.00", "2.00", "3.00", "4.00"])
    let interaction = ChartInteraction()

    interaction.scrubbedDate = start
    #expect(interaction.readout(for: subject)?.point.amount == decimal("1.00"))

    interaction.scrubbedDate = nil
    let readout = interaction.readout(for: subject)
    #expect(readout?.point.amount == decimal("4.00"))
    #expect(readout?.isScrubbing == false)
  }

  @Test func whenScrubbingAcrossContiguousDays_theCachedLookupShouldStayCorrect() {
    let subject = series((0..<30).map { "\($0 + 1).00" })
    let interaction = ChartInteraction()

    for index in 0..<30 {
      interaction.scrubbedDate = subject.points[index].date
      #expect(interaction.readout(for: subject)?.point == subject.points[index])
    }

    for index in (0..<30).reversed() {
      interaction.scrubbedDate = subject.points[index].date
      #expect(interaction.readout(for: subject)?.point == subject.points[index])
    }

    interaction.scrubbedDate = subject.points[27].date
    #expect(interaction.readout(for: subject)?.point == subject.points[27])
  }

  @Test func anchorSeries_shouldBeTheFirstFinishDrawn() {
    let section = PriceHistorySection(
      series: [series(["1.00", "2.00"]), series(["8.00", "9.00"], kind: .foil)],
      currency: "USD"
    )

    #expect(ChartDerivedData(section: section, isolatedKind: nil, range: .quarter).anchorSeries?.kind == .foil)
    #expect(ChartDerivedData(section: section, isolatedKind: .normal, range: .quarter).anchorSeries?.kind == .normal)
    #expect(ChartDerivedData(section: section, isolatedKind: .foil, range: .quarter).displayedSeries.count == 1)
  }

  @Test func displayedSeries_shouldBeOrderedFoilFirst() {
    let section = PriceHistorySection(
      series: [
        series(["1.00", "2.00"]),
        series(["8.00", "9.00"], kind: .foil),
        series(["4.00", "5.00"], kind: .etched),
      ],
      currency: "USD"
    )

    #expect(section.series.map(\.kind) == [.normal, .foil, .etched])
    #expect(
      ChartDerivedData(section: section, isolatedKind: nil, range: .quarter)
        .displayedSeries.map(\.kind) == [.foil, .etched, .normal]
    )
  }
}
