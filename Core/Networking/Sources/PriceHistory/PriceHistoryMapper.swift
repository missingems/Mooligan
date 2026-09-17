import Foundation

/// One row of MTGGraphQL's `prices` field, flattened away from Apollo's generated
/// types so the mapping below can be exercised without running codegen.
///
/// The schema declares every field except `currency` non-null, but these stay
/// optional: the integration test decodes raw JSON straight off the wire, where
/// a field can be absent, and a missing value should skip one row rather than
/// fail the whole response.
public struct MTGGraphQLPriceRow: Sendable, Equatable, Decodable {
  public let provider: String?
  public let date: String?
  public let cardType: String?
  public let listType: String?
  public let currency: String?
  /// `paper` or `mtgio`. Implied by the provider, so it is carried for
  /// diagnostics rather than filtered on.
  public let format: String?
  public let price: Double?

  public init(
    provider: String?,
    date: String?,
    cardType: String?,
    listType: String?,
    currency: String? = nil,
    format: String? = nil,
    price: Double?
  ) {
    self.provider = provider
    self.date = date
    self.cardType = cardType
    self.listType = listType
    self.currency = currency
    self.format = format
    self.price = price
  }
}

/// Turns MTGGraphQL price rows into chartable series.
///
/// MTGJSON returns every provider, finish and list type interleaved in one flat
/// array, so this filters down to a single comparable line before grouping.
public enum PriceHistoryMapper {
  public static func makeHistory(
    cardID: String,
    rows: [MTGGraphQLPriceRow],
    provider: PriceProvider,
    listType: PriceListType
  ) -> PriceHistory {
    var series: [PriceSeriesKind: [PricePoint]] = [:]
    var currency: String?

    for row in rows {
      guard
        matches(row.provider, provider.rawValue),
        matches(row.listType, listType.rawValue),
        let rawCardType = row.cardType,
        let kind = PriceSeriesKind(mtgGraphQLCardType: rawCardType),
        let rawDate = row.date,
        let date = day(from: rawDate),
        let price = row.price,
        price > 0
      else {
        continue
      }

      if currency == nil, let reported = row.currency, reported.isEmpty == false {
        currency = reported.uppercased()
      }

      series[kind, default: []].append(
        PricePoint(date: date, amount: Decimal(price))
      )
    }

    // A card printed in several sets can report the same day more than once;
    // keep one point per day and sort so Swift Charts gets a monotonic x axis.
    for kind in series.keys {
      guard let points = series[kind] else { continue }
      let deduped = Dictionary(points.map { ($0.date, $0) }, uniquingKeysWith: { _, last in last })
      series[kind] = deduped.values.sorted { $0.date < $1.date }
    }

    return PriceHistory(
      cardID: cardID,
      provider: provider,
      listType: listType,
      currency: currency,
      series: series
    )
  }

  /// The feed sends lowercase values, so the common case is a plain comparison; lowercasing
  /// allocates a string per row, which adds up over a card's several hundred rows.
  private static func matches(_ value: String?, _ expected: String) -> Bool {
    guard let value else { return false }
    return value == expected || value.lowercased() == expected
  }

  /// A `YYYY-MM-DD` day at UTC midnight.
  ///
  /// Parsed by hand because this runs for every row of every card, and `DateFormatter` goes
  /// through ICU (and a shared lock) each time. Anything not in that exact shape is left to
  /// `dayFormatter`, so unusual input is handled exactly as before.
  static func day(from text: String) -> Date? {
    fastDay(from: text) ?? dayFormatter.date(from: text)
  }

  static func fastDay(from text: String) -> Date? {
    var year = 0
    var month = 0
    var day = 0
    var index = 0
    for byte in text.utf8 {
      switch index {
      case 4, 7:
        guard byte == UInt8(ascii: "-") else { return nil }
      case 0...9:
        guard byte >= UInt8(ascii: "0"), byte <= UInt8(ascii: "9") else { return nil }
        let digit = Int(byte - UInt8(ascii: "0"))
        if index < 4 {
          year = year * 10 + digit
        } else if index < 7 {
          month = month * 10 + digit
        } else {
          day = day * 10 + digit
        }
      default:
        return nil
      }
      index += 1
    }

    guard index == 10, year >= 1, (1...12).contains(month), day >= 1, day <= daysIn(month: month, year: year) else {
      return nil
    }

    // Days since 1970-01-01 in the proleptic Gregorian calendar (Howard Hinnant's days_from_civil).
    let shiftedYear = month <= 2 ? year - 1 : year
    let era = shiftedYear / 400
    let yearOfEra = shiftedYear - era * 400
    let monthFromMarch = (month + 9) % 12
    let dayOfYear = (153 * monthFromMarch + 2) / 5 + day - 1
    let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
    let daysSinceEpoch = era * 146_097 + dayOfEra - 719_468
    return Date(timeIntervalSince1970: TimeInterval(daysSinceEpoch) * 86_400)
  }

  private static func daysIn(month: Int, year: Int) -> Int {
    switch month {
    case 2:
      let isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
      return isLeap ? 29 : 28
    case 4, 6, 9, 11:
      return 30
    default:
      return 31
    }
  }

  /// MTGJSON dates are plain `YYYY-MM-DD` with no zone; parse them as UTC so the
  /// same payload maps to the same instant regardless of the device's locale.
  static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()
}
