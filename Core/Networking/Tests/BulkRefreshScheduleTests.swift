@testable import Networking
import Foundation
import Testing

struct BulkRefreshScheduleTests {
  private var utc: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  private func date(_ iso: String) -> Date {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: iso)!
  }

  @Test func whenAfterTheBoundary_shouldAnchorToToday() {
    let boundary = BulkRefreshSchedule.lastDailyBoundary(before: date("2026-09-06T23:30:00Z"))

    #expect(boundary == date("2026-09-06T22:00:00Z"))
  }

  @Test func whenBeforeTheBoundary_shouldAnchorToYesterday() {
    let boundary = BulkRefreshSchedule.lastDailyBoundary(before: date("2026-09-06T09:00:00Z"))

    #expect(boundary == date("2026-09-05T22:00:00Z"))
  }

  @Test func whenTwoDevicesCheckedAtDifferentTimes_shouldAgreeOnWhatIsDue() {
    let now = date("2026-09-07T08:00:00Z")
    let earlyRiser = date("2026-09-06T23:00:00Z")
    let nightOwl = date("2026-09-07T02:00:00Z")

    #expect(BulkRefreshSchedule.isCheckDue(lastCheckedAt: earlyRiser, now: now) == false)
    #expect(BulkRefreshSchedule.isCheckDue(lastCheckedAt: nightOwl, now: now) == false)

    let afterNextBoundary = date("2026-09-07T22:00:01Z")
    #expect(BulkRefreshSchedule.isCheckDue(lastCheckedAt: earlyRiser, now: afterNextBoundary))
    #expect(BulkRefreshSchedule.isCheckDue(lastCheckedAt: nightOwl, now: afterNextBoundary))
  }

  @Test func whenNeverChecked_shouldBeDue() {
    #expect(BulkRefreshSchedule.isCheckDue(lastCheckedAt: nil, now: date("2026-09-06T09:00:00Z")))
  }

  @Test func whenTheDeviceWasOffForAWeek_shouldBeDueImmediately() {
    let lastChecked = date("2026-08-30T22:30:00Z")

    #expect(BulkRefreshSchedule.isCheckDue(lastCheckedAt: lastChecked, now: date("2026-09-06T09:00:00Z")))
  }

  @Test func whenCheckedJustAfterTheBoundary_shouldNotBeDueAgainThatDay() {
    let lastChecked = date("2026-09-06T22:05:00Z")

    #expect(
      BulkRefreshSchedule.isCheckDue(lastCheckedAt: lastChecked, now: date("2026-09-07T21:59:00Z"))
        == false
    )
  }

  @Test func nextDailyBoundary_shouldBeAWholeDayOnFromTheLastOne() {
    let now = date("2026-09-06T09:00:00Z")

    #expect(BulkRefreshSchedule.nextDailyBoundary(after: now) == date("2026-09-06T22:00:00Z"))
  }

  @Test func weeklyBoundary_shouldLandOnMonday() {
    let boundary = BulkRefreshSchedule.lastWeeklyBoundary(before: date("2026-09-06T09:00:00Z"))

    #expect(utc.component(.weekday, from: boundary) == 2)
    #expect(boundary == date("2026-08-31T22:00:00Z"))
  }

  @Test func whenIngestedSinceTheWeeklyBoundary_shouldNotBeDue() {
    let ingested = date("2026-09-01T10:00:00Z")

    #expect(
      BulkRefreshSchedule.isFullRefreshDue(lastIngestedAt: ingested, now: date("2026-09-06T09:00:00Z"))
        == false
    )
  }

  @Test func whenIngestedBeforeTheWeeklyBoundary_shouldBeDue() {
    let ingested = date("2026-08-30T10:00:00Z")

    #expect(
      BulkRefreshSchedule.isFullRefreshDue(lastIngestedAt: ingested, now: date("2026-09-06T09:00:00Z"))
    )
  }

  @Test func whenNeverIngested_shouldBeDue() {
    #expect(
      BulkRefreshSchedule.isFullRefreshDue(lastIngestedAt: nil, now: date("2026-09-06T09:00:00Z"))
    )
  }

  @Test func boundaryShouldAlwaysLandAtTheSameUTCHour() {
    for instant in [
      "2026-01-15T03:00:00Z", "2026-06-30T23:59:00Z", "2026-12-31T12:00:00Z",
    ] {
      let boundary = BulkRefreshSchedule.lastDailyBoundary(before: date(instant))
      let components = utc.dateComponents([.hour, .minute, .second], from: boundary)

      #expect(components.hour == BulkRefreshSchedule.dailyBoundaryHourUTC)
      #expect(components.minute == 0)
      #expect(components.second == 0)
    }
  }
}
