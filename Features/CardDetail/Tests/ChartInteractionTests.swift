@testable import CardDetail
import Foundation
import Networking
import Testing

struct ChartInteractionTests {
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

  @Test func indexOfPoint_shouldSnapToTheNearestObservation() {
    let subject = series(["1.00", "2.00", "3.00", "4.00"])

    #expect(subject.indexOfPoint(nearest: start.addingTimeInterval(-day)) == 0)
    #expect(subject.indexOfPoint(nearest: start.addingTimeInterval(2.4 * day)) == 2)
    #expect(subject.indexOfPoint(nearest: start.addingTimeInterval(2.6 * day)) == 3)
    #expect(subject.indexOfPoint(nearest: start.addingTimeInterval(100 * day)) == 3)
  }

  @Test func whenScrubbing_thePointShouldFollowTheScrubbedDay() {
    let subject = series(["1.00", "2.00", "3.00", "4.00"])
    let interaction = ChartInteraction()

    interaction.scrubbedDate = start.addingTimeInterval(2 * day)

    #expect(interaction.pointIndex(for: subject) == 2)
    #expect(interaction.point(in: subject, at: start.addingTimeInterval(0.9 * day))?.amount == decimal("2.00"))
  }

  @Test func whenTheScrubEnds_thePointShouldReturnToTheLatest() {
    let subject = series(["1.00", "2.00", "3.00", "4.00"])
    let interaction = ChartInteraction()

    interaction.scrubbedDate = start
    #expect(interaction.pointIndex(for: subject) == 0)

    interaction.endScrub()
    #expect(interaction.scrubbedDate == nil)
    #expect(interaction.pointIndex(for: subject) == subject.points.indices.last)
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

  @Test func isScrubbing_shouldOnlyFlipWhenAScrubStartsOrEnds() {
    let interaction = ChartInteraction()
    #expect(interaction.isScrubbing == false)

    interaction.scrubbedDate = start
    #expect(interaction.isScrubbing)

    interaction.scrubbedDate = start.addingTimeInterval(day)
    #expect(interaction.isScrubbing)

    interaction.endScrub()
    #expect(interaction.isScrubbing == false)
  }
}
