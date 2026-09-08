import Foundation
import Networking
import ScryfallKit

/// Everything the price chart draws, assembled once in the reducer.
///
/// The chart view used to fetch and derive all of this itself, in `body`. That
/// put a network call, a full set-list read and ~180 points of series splicing
/// on the path of every page the card pager created — including the neighbours
/// it renders ahead of time — which is what made swiping stutter. Building it in
/// an effect keeps the work off the main actor and, because the pager only asks
/// for the card that settled, does it once per card the reader actually looks at.
public struct PriceHistorySection: Equatable, Sendable {
  /// One finish's line, with the extents the chart needs already measured.
  ///
  /// The view used to derive these in `body`. That put a flatMap plus several
  /// min/max passes over ~180 points on every redraw — and the body redraws on
  /// every frame of a scrub, so it ran at 60hz while a finger was down. They are
  /// fixed the moment the series is built, so they are measured once here.
  public struct Series: Identifiable, Equatable, Sendable {
    public let kind: PriceSeriesKind
    public let points: [PricePoint]
    /// Lowest and highest price in this series.
    public let priceRange: ClosedRange<Double>
    /// First and last observation in this series.
    public let dateRange: ClosedRange<Date>

    public var id: String { kind.rawValue }

    /// `points` must be sorted ascending by date, which the mapper guarantees.
    init?(kind: PriceSeriesKind, points: [PricePoint]) {
      let values = points.map { ($0.amount as NSDecimalNumber).doubleValue }
        .filter(\.isFinite)
      guard
        points.count >= 2,
        let low = values.min(),
        let high = values.max(),
        let first = points.first?.date,
        let last = points.last?.date,
        last > first
      else {
        return nil
      }
      self.kind = kind
      self.points = points
      self.priceRange = low...max(high, low)
      self.dateRange = first...last
    }
  }

  public let series: [Series]
  public let currency: String
  public let releases: [SetReleaseMarker]
  /// Extents across every finish, for the default un-isolated view.
  public let priceRange: ClosedRange<Double>
  public let dateRange: ClosedRange<Date>

  init?(series: [Series], currency: String, releases: [SetReleaseMarker]) {
    guard
      let low = series.map(\.priceRange.lowerBound).min(),
      let high = series.map(\.priceRange.upperBound).max(),
      let first = series.map(\.dateRange.lowerBound).min(),
      let last = series.map(\.dateRange.upperBound).max()
    else {
      return nil
    }
    self.series = series
    self.currency = currency
    self.releases = releases
    self.priceRange = low...max(high, low)
    self.dateRange = first...max(last, first.addingTimeInterval(86_400))
  }
}

/// What the section shows right now. It is never absent from the layout: an
/// absent section that appears when a fetch lands grows the scroll content under
/// the reader, and the page jumps.
public enum PriceHistoryState: Equatable, Sendable {
  case loading
  /// The fetch resolved, and there is nothing to draw — no proxy configured, a
  /// rate limit, or a printing MTGJSON has never priced.
  case unavailable
  case data(PriceHistorySection)
}

extension PriceHistorySection {
  /// Turns a raw history plus today's Scryfall quote into chartable series.
  public static func makeState(
    card: Card,
    history: PriceHistory?,
    releases: [SetReleaseMarker],
    today: Date = PriceHistorySection.today
  ) -> PriceHistoryState {
    guard let history else { return .unavailable }

    let series = PriceSeriesKind.allCases.compactMap { kind in
      Series(
        kind: kind,
        points: withLiveLatest(
          history.series[kind] ?? [],
          scryfallQuote: scryfallQuote(card: card, kind: kind),
          today: today
        )
      )
    }

    // Markers outside what the chart plots would sit on an axis position that
    // does not exist, so they are trimmed to the span once it is known.
    guard
      let bounds = PriceHistorySection(series: series, currency: history.currency, releases: []),
      let section = PriceHistorySection(
        series: series,
        currency: history.currency,
        releases: releases.filter { bounds.dateRange.contains($0.date) }
      )
    else {
      return .unavailable
    }
    return .data(section)
  }

  /// Scryfall's live quote for one finish, when it has one.
  ///
  /// Scryfall's `usd` is TCGplayer's market price, which is the same series
  /// MTGJSON reports, so the two can be joined end to end.
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

  /// Swaps MTGJSON's trailing days for Scryfall's live number, so the chart ends
  /// on the same figure the buy links below it show.
  ///
  /// Only when MTGJSON is roughly current. A series that stopped a month ago is a
  /// card the feed dropped; bridging that gap with a straight line to today would
  /// invent a month of price action nobody observed.
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

  /// Today at UTC midnight, matching how `PriceHistoryMapper` parses MTGJSON's
  /// zone-less `YYYY-MM-DD` dates so the two land on the same x position.
  public static var today: Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return calendar.startOfDay(for: Date())
  }
}
