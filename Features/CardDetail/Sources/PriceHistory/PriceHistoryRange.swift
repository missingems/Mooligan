import Foundation

enum PriceHistoryRange: String, CaseIterable, Identifiable, Sendable {
  case week
  case month
  case quarter

  var id: String { rawValue }

  var days: Int {
    switch self {
    case .week: 7
    case .month: 30
    case .quarter: 90
    }
  }

  var label: String {
    switch self {
    case .week: String(localized: "Past Week")
    case .month: String(localized: "Past Month")
    case .quarter: String(localized: "Past 3 Months")
    }
  }

  func cutoff(endingAt last: Date) -> Date {
    last.addingTimeInterval(-Double(days) * 86_400)
  }

  static func available(forSpanOfDays days: Int) -> [PriceHistoryRange] {
    let narrower = allCases.filter { $0.days < days }
    guard let covering = allCases.first(where: { $0.days >= days }) else { return narrower }
    return narrower + [covering]
  }

  static func widest(forSpanOfDays days: Int) -> PriceHistoryRange {
    available(forSpanOfDays: days).last ?? .quarter
  }
}
