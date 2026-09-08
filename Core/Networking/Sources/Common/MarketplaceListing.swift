import Foundation
import ScryfallKit

/// A storefront Scryfall can hand a card off to.
///
/// Scryfall's `purchase_uris` and its `prices` line up one-to-one: each
/// marketplace quotes in exactly one currency, so the two can be zipped into a
/// single "where to buy, and for how much" row.
public enum Marketplace: String, Sendable, CaseIterable, Identifiable {
  case tcgplayer
  case cardmarket
  case cardhoarder

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .tcgplayer: "TCGplayer"
    case .cardmarket: "Cardmarket"
    case .cardhoarder: "Cardhoarder"
    }
  }

  /// `cardhoarder` sells MTGO cards and quotes event tickets, which is not an ISO
  /// currency — `MarketplaceListing.isTickets` exists so the UI can format it as
  /// a bare number with a "tix" suffix instead of feeding it to a currency style.
  public var currencyCode: String {
    switch self {
    case .tcgplayer: "USD"
    case .cardmarket: "EUR"
    case .cardhoarder: "TIX"
    }
  }

  /// Paper marketplaces sell physical finishes; MTGO has no foils to speak of.
  public var isDigital: Bool { self == .cardhoarder }
}

/// One marketplace row: where to buy, and what it quotes per finish.
public struct MarketplaceListing: Equatable, Sendable, Identifiable {
  public let marketplace: Marketplace
  public let url: URL
  /// Only the finishes this marketplace actually quotes. A card with no foil
  /// printing simply has no `.foil` entry rather than a zero.
  public let prices: [PriceSeriesKind: Decimal]

  public var id: String { marketplace.rawValue }

  public init(marketplace: Marketplace, url: URL, prices: [PriceSeriesKind: Decimal]) {
    self.marketplace = marketplace
    self.url = url
    self.prices = prices
  }

  public var isTickets: Bool { marketplace == .cardhoarder }

  /// Finishes in the order a player expects to read them.
  public var orderedPrices: [(kind: PriceSeriesKind, amount: Decimal)] {
    PriceSeriesKind.allCases.compactMap { kind in
      prices[kind].map { (kind, $0) }
    }
  }
}

public extension MarketplaceListing {
  /// Builds the rows for a card, skipping any marketplace that has no link or no
  /// price — an empty row is a dead end, and Scryfall omits both together for
  /// cards a storefront has never carried.
  static func listings(
    purchaseURIs: [String: String]?,
    prices: Card.Prices
  ) -> [MarketplaceListing] {
    Marketplace.allCases.compactMap { marketplace in
      guard
        let raw = purchaseURIs?[marketplace.rawValue],
        let url = URL(string: raw)
      else {
        return nil
      }

      let quoted: [PriceSeriesKind: Decimal]
      switch marketplace {
      case .tcgplayer:
        quoted = amounts([
          .normal: prices.usd, .foil: prices.usdFoil, .etched: prices.usdEtched,
        ])
      case .cardmarket:
        quoted = amounts([
          .normal: prices.eur, .foil: prices.eurFoil, .etched: prices.eurEtched,
        ])
      case .cardhoarder:
        quoted = amounts([.normal: prices.tix])
      }

      guard quoted.isEmpty == false else { return nil }
      return MarketplaceListing(marketplace: marketplace, url: url, prices: quoted)
    }
  }

  /// Scryfall sends prices as strings and omits the key entirely when it has no
  /// quote; `"0.00"` still shows up for cards nobody stocks, and a free card is a
  /// missing price rather than a real one.
  private static func amounts(_ raw: [PriceSeriesKind: String?]) -> [PriceSeriesKind: Decimal] {
    raw.reduce(into: [:]) { result, entry in
      guard
        let string = entry.value,
        let amount = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")),
        amount > 0
      else {
        return
      }
      result[entry.key] = amount
    }
  }
}
