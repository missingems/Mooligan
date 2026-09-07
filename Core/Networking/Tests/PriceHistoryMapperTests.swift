@testable import Networking
import Foundation
import Testing

/// Exercises the MTGGraphQL -> chart series mapping against a payload shaped like
/// the documented `prices { provider date cardType listType price }` response.
struct PriceHistoryMapperTests {
  private let cardID = "d8b3e4f1-0000-4000-8000-000000000001"

  private var wideWindow: DateInterval {
    DateInterval(start: .distantPast, end: .distantFuture)
  }

  private func row(
    provider: String = "tcgplayer",
    date: String,
    cardType: String = "normal",
    listType: String = "retail",
    currency: String? = nil,
    price: Double?
  ) -> MTGGraphQLPriceRow {
    MTGGraphQLPriceRow(
      provider: provider,
      date: date,
      cardType: cardType,
      listType: listType,
      currency: currency,
      price: price
    )
  }

  private func map(
    _ rows: [MTGGraphQLPriceRow],
    provider: PriceProvider = .tcgplayer,
    listType: PriceListType = .retail,
    window: DateInterval? = nil
  ) -> PriceHistory {
    PriceHistoryMapper.makeHistory(
      cardID: cardID,
      rows: rows,
      provider: provider,
      listType: listType,
      window: window ?? wideWindow
    )
  }

  @Test("Keeps only the requested provider and list type")
  func filtersProviderAndListType() {
    let history = map([
      row(provider: "tcgplayer", date: "2026-06-01", price: 10),
      row(provider: "cardkingdom", date: "2026-06-01", price: 99),
      row(provider: "tcgplayer", date: "2026-06-02", listType: "buylist", price: 4),
      row(provider: "tcgplayer", date: "2026-06-02", price: 11),
    ])

    #expect(history.series[.normal]?.map(\.amount) == [10, 11])
  }

  @Test("Splits finishes into separate series")
  func splitsFinishes() {
    let history = map([
      row(date: "2026-06-01", cardType: "normal", price: 10),
      row(date: "2026-06-01", cardType: "foil", price: 25),
      row(date: "2026-06-01", cardType: "etched", price: 40),
    ])

    #expect(history.series[.normal]?.first?.amount == 10)
    #expect(history.series[.foil]?.first?.amount == 25)
    #expect(history.series[.etched]?.first?.amount == 40)
  }

  @Test("Accepts the alternate spellings of etched foil")
  func normalizesEtchedSpellings() {
    for spelling in ["etched", "Foil Etched", "foiletched"] {
      let history = map([row(date: "2026-06-01", cardType: spelling, price: 7)])
      #expect(history.series[.etched]?.count == 1, "failed for \(spelling)")
    }
  }

  @Test("Sorts by date and collapses duplicate days to the last value")
  func dedupesAndSorts() {
    let history = map([
      row(date: "2026-06-03", price: 30),
      row(date: "2026-06-01", price: 10),
      row(date: "2026-06-02", price: 20),
      row(date: "2026-06-02", price: 22),
    ])

    let points = history.series[.normal] ?? []
    #expect(points.map(\.amount) == [10, 22, 30])
    #expect(points.map(\.date) == points.map(\.date).sorted())
  }

  @Test("Parses dates as UTC regardless of the ambient time zone")
  func parsesDatesAsUTC() throws {
    let history = map([row(date: "2026-06-01", price: 10)])
    let date = try #require(history.series[.normal]?.first?.date)

    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = try #require(TimeZone(identifier: "UTC"))
    let parts = utc.dateComponents([.year, .month, .day, .hour], from: date)

    #expect(parts.year == 2026)
    #expect(parts.month == 6)
    #expect(parts.day == 1)
    #expect(parts.hour == 0)
  }

  @Test("Drops points outside the requested window")
  func clipsToWindow() throws {
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = try #require(TimeZone(identifier: "UTC"))
    let start = try #require(PriceHistoryMapper.dayFormatter.date(from: "2026-06-02"))
    let end = try #require(PriceHistoryMapper.dayFormatter.date(from: "2026-06-03"))

    let history = map(
      [
        row(date: "2026-06-01", price: 10),
        row(date: "2026-06-02", price: 20),
        row(date: "2026-06-03", price: 30),
        row(date: "2026-06-04", price: 40),
      ],
      window: DateInterval(start: start, end: end)
    )

    #expect(history.series[.normal]?.map(\.amount) == [20, 30])
  }

  @Test("Skips rows with missing or unusable fields")
  func skipsUnusableRows() {
    let history = map([
      row(date: "2026-06-01", price: nil),
      row(date: "not-a-date", price: 10),
      row(date: "2026-06-02", cardType: "sketch", price: 10),
      row(date: "2026-06-03", price: 0),
      row(date: "2026-06-04", price: 15),
    ])

    #expect(history.series[.normal]?.map(\.amount) == [15])
  }

  @Test("Reports emptiness and chartability")
  func reportsEmptinessAndChartability() {
    let empty = map([])
    #expect(empty.isEmpty)
    #expect(empty.chartableKinds.isEmpty)

    // One point is not a line, so it must not be offered as chartable.
    let single = map([row(date: "2026-06-01", price: 10)])
    #expect(single.isEmpty == false)
    #expect(single.chartableKinds.isEmpty)

    let pair = map([
      row(date: "2026-06-01", price: 10),
      row(date: "2026-06-02", price: 11),
    ])
    #expect(pair.chartableKinds == [.normal])
  }

  @Test("Uses the currency the API reports, falling back to the provider's")
  func resolvesCurrency() {
    let reported = map(
      [
        row(provider: "cardmarket", date: "2026-06-01", currency: "eur", price: 3),
        row(provider: "cardmarket", date: "2026-06-02", currency: "eur", price: 4),
      ],
      provider: .cardmarket
    )
    #expect(reported.currency == "EUR")

    // No currency on the wire: fall back rather than mislabel the axis.
    let missing = map([row(date: "2026-06-01", price: 3)])
    #expect(missing.currency == "USD")
  }

  @Test("Decodes the real MTGGraphQL prices payload")
  func decodesRealPayload() throws {
    // Field set and types taken from the fetched schema: every field but
    // `currency` is non-null, `price` is a Float, `format` is paper/mtgio.
    let json = """
      [
        { "provider": "cardkingdom", "date": "2026-06-01", "cardType": "normal",
          "listType": "retail", "currency": "USD", "format": "paper", "price": 0.49 },
        { "provider": "tcgplayer", "date": "2026-06-01", "cardType": "normal",
          "listType": "retail", "currency": "USD", "format": "paper", "price": 0.32 },
        { "provider": "tcgplayer", "date": "2026-06-01", "cardType": "foil",
          "listType": "retail", "currency": "USD", "format": "paper", "price": 1.75 },
        { "provider": "tcgplayer", "date": "2026-06-02", "cardType": "normal",
          "listType": "buylist", "currency": "USD", "format": "paper", "price": 0.11 },
        { "provider": "tcgplayer", "date": "2026-06-02", "cardType": "normal",
          "listType": "retail", "currency": "USD", "format": "paper", "price": 0.35 }
      ]
      """
    let rows = try JSONDecoder().decode([MTGGraphQLPriceRow].self, from: Data(json.utf8))
    #expect(rows.count == 5)
    #expect(rows.first?.format == "paper")

    let history = map(rows)
    #expect(history.series[.normal]?.map(\.amount) == [0.32, 0.35])
    #expect(history.series[.foil]?.map(\.amount) == [1.75])
    #expect(history.provider == .tcgplayer)
    #expect(history.listType == .retail)
    #expect(history.currency == "USD")
  }
}
