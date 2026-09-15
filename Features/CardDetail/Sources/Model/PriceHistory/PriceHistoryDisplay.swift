import Foundation
import Networking
import ScryfallKit

struct PriceHistoryDisplay: Equatable, Sendable {
  enum Status: Equatable, Sendable {
    case loading
    case loaded
    case unavailable
    case failed
  }

  var status: Status
  var prices: [FinishPrice]
  var buyBack: BuyBackSummary
  /// The card's TCGplayer page, which the prices open. TCGplayer lists every finish on one page, and
  /// its market price is the one the toolbar and chart show.
  var tcgplayerURL: URL?
  var chart: ChartDerivedData
  var axis: PriceChartStyle.PriceAxis
  /// Every charted day's price, formatted ahead of time, so scrubbing only picks one.
  var scrubPrices: [PriceSeriesKind: [String]]

  var hasChart: Bool { chart.plotSeries.isEmpty == false }

  /// Every finish, then the buy back ratio.
  var toolbarEntries: [PriceHistoryToolbarEntry] {
    prices.map { .finish($0.kind) } + [.buyBack]
  }

  func price(for kind: PriceSeriesKind) -> FinishPrice? {
    prices.first { $0.kind == kind }
  }

  /// The price shown for `kind` on the scrubbed day, or its latest price when nothing is scrubbed.
  func priceText(for price: FinishPrice, interaction: ChartInteraction) -> String {
    guard
      let series = chart.series(for: price.kind),
      let texts = scrubPrices[price.kind],
      let index = interaction.pointIndex(for: series),
      texts.indices.contains(index)
    else {
      return price.priceText
    }
    return texts[index]
  }
}

extension PriceHistoryDisplay {
  static func loading(card: Card, labels: PriceHistoryLabels) -> PriceHistoryDisplay {
    make(card: card, state: .loading, labels: labels)
  }

  static func make(card: Card, state: PriceHistoryState, labels: PriceHistoryLabels) -> PriceHistoryDisplay {
    let status: Status
    let section: PriceHistorySection
    switch state {
    case .loading:
      status = .loading
      section = PriceHistoryState.empty
    case .unavailable:
      status = .unavailable
      section = PriceHistoryState.empty
    case .failed:
      status = .failed
      section = PriceHistoryState.empty
    case let .data(value):
      status = .loaded
      section = value
    }

    let chart = ChartDerivedData(section: section)
    let currency = status == .loaded && section.currency.isEmpty == false ? section.currency : "USD"
    let kinds = finishes(of: card, charted: chart.series.map(\.kind))
    let format = PriceChartStyle.price(currency)
    let missing = PriceChartStyle.missingValue
    let quotes = kinds.reduce(into: [PriceSeriesKind: Decimal]()) { quotes, kind in
      quotes[kind] = PriceHistorySection.scryfallQuote(card: card, kind: kind)
    }

    let prices = kinds.map { kind in
      let price = chart.series(for: kind)?.points.last?.amount ?? quotes[kind]
      return FinishPrice(
        kind: kind,
        label: PriceChartStyle.label(for: kind),
        priceText: price?.formatted(format) ?? missing,
        isAvailable: price != nil
      )
    }

    let scrubPrices = chart.series.reduce(into: [PriceSeriesKind: [String]]()) { frames, series in
      frames[series.kind] = series.points.map { $0.amount.formatted(format) }
    }

    // Without history (loading, or none to be had) the chart still spans the last three months, and
    // its axis is estimated from the Scryfall prices, so landing prices only adjust it.
    let axis = (chart.plotSeries.isEmpty
      ? PriceChartStyle.estimatedPriceAxis(around: quotes.values.map(\.doubleValue))
      : PriceChartStyle.priceAxis(for: chart.priceRange)
    ).labeled(currencyCode: currency)

    return PriceHistoryDisplay(
      status: status,
      prices: prices,
      buyBack: buyBack(kinds: kinds, quote: section.buylistQuote, format: format, missing: missing),
      tcgplayerURL: tcgplayerURL(of: card),
      chart: chart,
      axis: axis,
      scrubPrices: scrubPrices
    )
  }

  /// Regular and foil always show, so the toolbar keeps its shape: a card printed in etched foil but
  /// not foil shows etched in foil's place, and a card with both shows all three.
  static func finishes(of card: Card, charted: [PriceSeriesKind]) -> [PriceSeriesKind] {
    let kinds = Set(card.finishes.compactMap { finish -> PriceSeriesKind? in
      switch finish {
      case .nonfoil: .normal
      case .foil, .glossy: .foil
      case .etched: .etched
      case .unknown: nil
      }
    }).union(charted)

    var finishes: [PriceSeriesKind] = [.normal]
    if kinds.contains(.foil) || kinds.contains(.etched) == false {
      finishes.append(.foil)
    }
    if kinds.contains(.etched) {
      finishes.append(.etched)
    }
    return finishes
  }

  /// Scryfall's TCGplayer link for the card, when it is a secure web address.
  static func tcgplayerURL(of card: Card) -> URL? {
    guard
      let raw = card.purchaseUris?["tcgplayer"],
      let components = URLComponents(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
      components.scheme?.lowercased() == "https",
      components.host?.isEmpty == false
    else {
      return nil
    }
    return components.url
  }

  private static func buyBack(
    kinds: [PriceSeriesKind],
    quote: BuylistQuote?,
    format: Decimal.FormatStyle.Currency,
    missing: String
  ) -> BuyBackSummary {
    let finishes = kinds.compactMap { kind -> FinishBuyBack? in
      guard let price = quote?.buylist(for: kind) else { return nil }
      return FinishBuyBack(
        kind: kind,
        label: PriceChartStyle.label(for: kind),
        priceText: price.formatted(format),
        ratioText: quote?.ratio(for: kind).map(PriceChartStyle.ratioText)
      )
    }
    let ratios = kinds.compactMap { quote?.ratio(for: $0) }

    return BuyBackSummary(
      provider: quote?.provider ?? PriceHistorySection.buylistProvider,
      ratioText: PriceChartStyle.ratioRangeText(ratios) ?? missing,
      finishes: finishes
    )
  }
}
