@testable import Networking
import Dependencies
import Foundation
import SQLiteData

final class TestClock: @unchecked Sendable {
  private let lock = NSLock()
  private var _now: Date

  init(_ now: Date = Date(timeIntervalSince1970: 1_800_000_000)) {
    _now = now
  }

  var now: Date {
    get { lock.withLock { _now } }
    set { lock.withLock { _now = newValue } }
  }

  func advance(by interval: TimeInterval) {
    lock.withLock { _now = _now.addingTimeInterval(interval) }
  }

  func advancePastDailyBoundary() {
    now = BulkRefreshSchedule.nextDailyBoundary(after: now).addingTimeInterval(60)
  }

  func advancePastWeeklyBoundary() {
    var candidate = now
    let start = BulkRefreshSchedule.lastWeeklyBoundary(before: now)

    while BulkRefreshSchedule.lastWeeklyBoundary(before: candidate) <= start {
      candidate = BulkRefreshSchedule.nextDailyBoundary(after: candidate).addingTimeInterval(60)
    }

    now = candidate
  }
}

func makeTestDatabase() throws -> any DatabaseWriter {
  try withDependencies {
    $0.context = .test
  } operation: {
    try appDatabase()
  }
}
