import Foundation

/// A single dated price observation for one card, in one currency, for one finish.
public struct PricePoint: Sendable, Equatable, Identifiable {
  public let date: Date
  public let amount: Decimal

  public var id: Date { date }

  public init(date: Date, amount: Decimal) {
    self.date = date
    self.amount = amount
  }
}

/// The finishes MTGGraphQL reports under `prices.cardType`, narrowed to the ones
/// the card detail view offers. `foilEtched` only exists for a handful of sets.
public enum PriceSeriesKind: String, Sendable, CaseIterable, Identifiable {
  case normal
  case foil
  case etched

  public var id: String { rawValue }

  /// MTGGraphQL spells etched foils `etched`; guard against the older `foil etched`.
  init?(mtgGraphQLCardType: String) {
    switch mtgGraphQLCardType.lowercased() {
    case "normal": self = .normal
    case "foil": self = .foil
    case "etched", "foil etched", "foiletched": self = .etched
    default: return nil
    }
  }
}

/// Which price provider to chart. MTGJSON aggregates several; mixing them in one
/// line is meaningless, so the client picks one and the UI can offer a switch.
public enum PriceProvider: String, Sendable, CaseIterable, Identifiable {
  case tcgplayer
  case cardkingdom
  case cardmarket
  case cardsphere
  case cardhoarder

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .tcgplayer: "TCGplayer"
    case .cardkingdom: "Card Kingdom"
    case .cardmarket: "Cardmarket"
    case .cardsphere: "Cardsphere"
    case .cardhoarder: "Cardhoarder"
    }
  }

  /// `cardhoarder` quotes MTGO tickets, `cardmarket` euros, the rest US dollars.
  public var currencyCode: String {
    switch self {
    case .cardmarket: "EUR"
    case .cardhoarder: "TIX"
    default: "USD"
    }
  }
}

/// Retail (what you pay) vs buylist (what a vendor pays you).
public enum PriceListType: String, Sendable {
  case retail
  case buylist
}

/// Price history for one card, keyed by finish. Series are sorted ascending by date.
public struct PriceHistory: Sendable, Equatable {
  public let cardID: String
  public let provider: PriceProvider
  public let listType: PriceListType
  /// ISO code as reported by MTGGraphQL's `CardPrices.currency`, falling back to
  /// the provider's usual currency when the API omits it.
  public let currency: String
  public let series: [PriceSeriesKind: [PricePoint]]

  public init(
    cardID: String,
    provider: PriceProvider,
    listType: PriceListType,
    currency: String? = nil,
    series: [PriceSeriesKind: [PricePoint]]
  ) {
    self.cardID = cardID
    self.provider = provider
    self.listType = listType
    self.currency = currency ?? provider.currencyCode
    self.series = series
  }

  public static func empty(cardID: String, provider: PriceProvider) -> PriceHistory {
    PriceHistory(cardID: cardID, provider: provider, listType: .retail, series: [:])
  }

  public var isEmpty: Bool { series.values.allSatisfy(\.isEmpty) }

  /// Finishes that actually carry at least two points — anything less can't be a line.
  public var chartableKinds: [PriceSeriesKind] {
    PriceSeriesKind.allCases.filter { (series[$0]?.count ?? 0) >= 2 }
  }
}

/// The move between two observations, as an absolute amount and a fraction.
///
/// Kept as a value over the two `PricePoint`s rather than two bare numbers so the
/// UI can label a comparison with the dates it actually spans.
public struct PriceChange: Sendable, Equatable {
  public let start: PricePoint
  public let end: PricePoint

  public init(start: PricePoint, end: PricePoint) {
    self.start = start
    self.end = end
  }

  public var absolute: Decimal { end.amount - start.amount }

  /// `nil` when the baseline is zero — a percentage off zero is undefined, and
  /// MTGJSON does report 0.00 for some listings.
  public var fraction: Double? {
    let base = (start.amount as NSDecimalNumber).doubleValue
    let delta = (absolute as NSDecimalNumber).doubleValue
    guard base != 0, base.isFinite, delta.isFinite else { return nil }
    return delta / base
  }

  public var isIncrease: Bool { absolute > 0 }
  public var isDecrease: Bool { absolute < 0 }
}

public extension BidirectionalCollection where Element == PricePoint {
  /// The change across the whole series. `nil` for fewer than two points, where
  /// there is nothing to compare against.
  var change: PriceChange? {
    guard count >= 2, let start = first, let end = last else { return nil }
    return PriceChange(start: start, end: end)
  }
}

/// Everything the price feed will give us.
///
/// The chart used to ask for a fixed 92 day window, which was a cap the data did
/// not need: MTGJSON retains what it retains — around 90 days for a card in
/// print, a handful of days for one released last week — so an explicit window
/// could only ever hide history, never add any.
public extension DateInterval {
  static var allPriceHistory: DateInterval {
    DateInterval(start: .distantPast, end: .distantFuture)
  }
}
