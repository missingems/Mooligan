import Foundation
import Networking
import ScryfallKit

extension PriceHistorySection {
  /// The series the chart plots.
  public static let chartProvider: PriceProvider = .tcgplayer

  /// The vendor the buy back price and ratio come from.
  ///
  /// TCGplayer is the market the chart follows, but it publishes retail only —
  /// the feed carries a buylist for Card Kingdom alone. Both figures therefore
  /// come from Card Kingdom, and the ratio is taken against Card Kingdom's own
  /// retail rather than TCGplayer's, so it compares one vendor's two prices.
  public static let buylistProvider: PriceProvider = .cardkingdom

  public static let chartRequest = PriceSeriesRequest(
    provider: chartProvider,
    listType: .retail
  )

  public static let priceRequests: [PriceSeriesRequest] = [
    chartRequest,
    PriceSeriesRequest(provider: buylistProvider, listType: .retail),
    PriceSeriesRequest(provider: buylistProvider, listType: .buylist),
  ]

  public static func buylistQuote(
    from histories: [PriceSeriesRequest: PriceHistory]
  ) -> BuylistQuote? {
    BuylistQuote(
      provider: buylistProvider,
      retail: histories[PriceSeriesRequest(provider: buylistProvider, listType: .retail)],
      buylist: histories[PriceSeriesRequest(provider: buylistProvider, listType: .buylist)]
    )
  }

  public static func makeState(
    card: Card,
    history: PriceHistory?,
    buylistQuote: BuylistQuote? = nil,
    today: Date = PriceHistorySection.today
  ) -> PriceHistoryState {
    guard let history else { return .unavailable }

    let releaseDate = UTCDay.date(from: card.releasedAt)

    let series = PriceSeriesKind.allCases.compactMap { kind in
      Series(
        kind: kind,
        points: withLiveLatest(
          onOrAfterRelease(pricedPoints(history.series[kind] ?? []), releaseDate: releaseDate),
          scryfallQuote: scryfallQuote(card: card, kind: kind),
          today: today
        )
      )
    }

    guard series.isEmpty == false else { return .unavailable }

    let section = PriceHistorySection(
      series: series,
      currency: history.currency,
      buylistQuote: buylistQuote
    )

    return .data(section)
  }

  static func pricedPoints(_ points: [PricePoint]) -> [PricePoint] {
    points.filter { $0.amount > 0 }
  }

  static func onOrAfterRelease(_ points: [PricePoint], releaseDate: Date?) -> [PricePoint] {
    guard let releaseDate else { return points }
    return points.filter { $0.date >= releaseDate }
  }

  static func scryfallQuote(card: Card, kind: PriceSeriesKind) -> Decimal? {
    let raw: String? = switch kind {
    case .normal: card.prices.usd
    case .foil: card.prices.usdFoil
    case .etched: card.prices.usdEtched
    }
    guard
      let raw,
      let amount = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")),
      amount > 0
    else {
      return nil
    }
    return amount
  }

  static func withLiveLatest(
    _ points: [PricePoint],
    scryfallQuote: Decimal?,
    today: Date
  ) -> [PricePoint] {
    guard
      let scryfallQuote,
      let last = points.last?.date,
      last > today.addingTimeInterval(-7 * 86_400)
    else {
      return points
    }
    var merged = points.filter { $0.date < today }
    merged.append(PricePoint(date: today, amount: scryfallQuote))
    return merged
  }

  public static var today: Date { UTCDay.today }
}
