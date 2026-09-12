import Foundation
import Networking
import ScryfallKit

extension PriceHistorySection {
  public static func makeState(
    card: Card,
    history: PriceHistory?,
    releases: [SetReleaseMarker],
    today: Date = PriceHistorySection.today
  ) -> PriceHistoryState {
    guard let history else { return .unavailable }

    let releaseDate = UTCDay.date(from: card.releasedAt)

    let series = PriceSeriesKind.allCases.compactMap { kind in
      Series(
        kind: kind,
        points: withLiveLatest(
          onOrAfterRelease(history.series[kind] ?? [], releaseDate: releaseDate),
          scryfallQuote: scryfallQuote(card: card, kind: kind),
          today: today
        )
      )
    }

    guard series.isEmpty == false else { return .unavailable }

    let bounds = PriceHistorySection(series: series, currency: history.currency, releases: releases)

    let section = PriceHistorySection(
      series: series,
      currency: history.currency,
      releases: releases.filter { bounds.dateRange.contains($0.date) }
    )

    return .data(section)
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
