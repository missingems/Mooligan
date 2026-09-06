import Foundation

public enum BulkRefreshSchedule {
  public static let dailyBoundaryHourUTC = 22

  public static let weeklyBoundaryWeekday = 2

  static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  public static func lastDailyBoundary(before now: Date) -> Date {
    let calendar = calendar
    var components = calendar.dateComponents([.year, .month, .day], from: now)
    components.hour = dailyBoundaryHourUTC

    guard let todaysBoundary = calendar.date(from: components) else { return now }

    return todaysBoundary <= now
      ? todaysBoundary
      : calendar.date(byAdding: .day, value: -1, to: todaysBoundary) ?? todaysBoundary
  }

  public static func lastWeeklyBoundary(before now: Date) -> Date {
    let calendar = calendar
    var boundary = lastDailyBoundary(before: now)

    for _ in 0..<7 {
      if calendar.component(.weekday, from: boundary) == weeklyBoundaryWeekday {
        return boundary
      }
      guard let previous = calendar.date(byAdding: .day, value: -1, to: boundary) else { break }
      boundary = previous
    }

    return boundary
  }

  public static func nextDailyBoundary(after now: Date) -> Date {
    let boundary = lastDailyBoundary(before: now)
    return calendar.date(byAdding: .day, value: 1, to: boundary) ?? now.addingTimeInterval(86_400)
  }

  public static func isCheckDue(lastCheckedAt: Date?, now: Date) -> Bool {
    guard let lastCheckedAt else { return true }
    return lastCheckedAt < lastDailyBoundary(before: now)
  }

  public static func isFullRefreshDue(lastIngestedAt: Date?, now: Date) -> Bool {
    guard let lastIngestedAt else { return true }
    return lastIngestedAt < lastWeeklyBoundary(before: now)
  }
}
