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
    listType: PriceListType,
    window: DateInterval
  ) -> PriceHistory {
    var series: [PriceSeriesKind: [PricePoint]] = [:]
    var currency: String?

    for row in rows {
      guard
        row.provider?.lowercased() == provider.rawValue,
        row.listType?.lowercased() == listType.rawValue,
        let rawCardType = row.cardType,
        let kind = PriceSeriesKind(mtgGraphQLCardType: rawCardType),
        let rawDate = row.date,
        let date = dayFormatter.date(from: rawDate),
        window.contains(date),
        let price = row.price,
        price > 0
      else {
        continue
      }

      // Take the currency the API reports rather than assuming one per provider.
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
