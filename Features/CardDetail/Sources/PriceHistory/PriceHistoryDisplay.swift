import Foundation
import Networking
import ScryfallKit

public struct PriceHistoryUpdate: Equatable, Sendable {
  let display: PriceHistoryDisplay
}

struct PriceHistoryDisplay: Equatable, Sendable {
  enum Status: Equatable, Sendable {
    case loading
    case loaded
    case unavailable
    case failed
  }

  struct Change: Equatable, Sendable {
    let text: String
    let direction: PriceChartStyle.ChangeDirection
    var isKnown = true

    static let flat = Change(text: PriceChartStyle.flatChangeText, direction: .flat)
    static let unknown = Change(text: PriceChartStyle.unavailableValue, direction: .flat, isKnown: false)
  }

  struct SummaryItem: Equatable, Sendable, Identifiable {
    let kind: PriceSeriesKind
    let label: String
    let priceText: String
    let change: Change

    var id: PriceSeriesKind { kind }
  }

  struct StatsColumn: Equatable, Sendable, Identifiable {
    let kind: PriceSeriesKind
    let label: String
    let isAvailable: Bool

    var id: PriceSeriesKind { kind }
  }

  struct StatsRow: Equatable, Sendable, Identifiable {
    let title: String
    let values: [String]

    var id: String { title }
  }

  struct ScrubFrames: Equatable, Sendable {
    let prices: [String]
    let changes: [Change]
  }

  var status: Status
  var currencyCode: String
  var summary: [SummaryItem]
  var statsTitles: [String]
  var statsColumns: [StatsColumn]
  var statsRows: [StatsRow]
  var chart: ChartDerivedData
  var axis: PriceChartStyle.PriceAxis
  var scrubFrames: [PriceSeriesKind: ScrubFrames]
  var widestPriceText: String
  var widestChange: Change
  var retailQuotes: [PriceProvider: RetailQuote]

  var hasChart: Bool { chart.plotSeries.isEmpty == false }
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
    let isLoading = status == .loading
    // A dash holds the place while prices load; once loading is over, anything still missing is N/A.
    let missing = isLoading ? PriceChartStyle.missingValue : PriceChartStyle.unavailableValue
    let quotes = kinds.reduce(into: [PriceSeriesKind: Decimal]()) { quotes, kind in
      quotes[kind] = PriceHistorySection.scryfallQuote(card: card, kind: kind)
    }

    let summary = kinds.map { kind -> SummaryItem in
      let label = PriceChartStyle.label(for: kind)
      if let readout = chart.series(for: kind)?.latestReadout {
        return SummaryItem(
          kind: kind,
          label: label,
          priceText: readout.point.amount.formatted(format),
          change: change(readout.change) ?? .unknown
        )
      }
      // The pill is there from the start, showing no change while loading, so prices landing only
      // change its text instead of making it appear.
      return SummaryItem(
        kind: kind,
        label: label,
        priceText: quotes[kind]?.formatted(format) ?? missing,
        change: isLoading ? .flat : .unknown
      )
    }

    // Without a chart for a finish, its Scryfall price is the one figure there is, so once loading
    // is over it stands in for that finish's low and high.
    func rangeFallback(_ kind: PriceSeriesKind) -> String {
      guard isLoading == false, let quote = quotes[kind] else { return missing }
      return quote.formatted(format)
    }

    let columns = kinds.map { kind in
      StatsColumn(
        kind: kind,
        label: PriceChartStyle.label(for: kind),
        isAvailable: isLoading || chart.isAvailable(kind) || chart.buylist(for: kind) != nil || quotes[kind] != nil
      )
    }

    let rows: [StatsRow] = [
      StatsRow(title: labels.low, values: kinds.map { kind in
        chart.range(for: kind).map { $0.lowerBound.formatted(format) } ?? rangeFallback(kind)
      }),
      StatsRow(title: labels.high, values: kinds.map { kind in
        chart.range(for: kind).map { $0.upperBound.formatted(format) } ?? rangeFallback(kind)
      }),
      StatsRow(title: labels.buylist, values: kinds.map { kind in
        chart.buylist(for: kind).map { $0.formatted(format) } ?? missing
      }),
      StatsRow(title: labels.spread, values: kinds.map { kind in
        chart.spread(for: kind).map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? missing
      }),
    ]

    var frames: [PriceSeriesKind: ScrubFrames] = [:]
    var widestPrice = ""
    var widestChange = Change.flat
    for series in chart.series {
      let prices = series.points.map { $0.amount.formatted(format) }
      let changes = series.points.indices.map { index in
        change(series.dayChange(endingAt: index)) ?? .flat
      }
      frames[series.kind] = ScrubFrames(prices: prices, changes: changes)
      if let longest = prices.max(by: { $0.count < $1.count }), longest.count > widestPrice.count {
        widestPrice = longest
      }
      if let longest = changes.max(by: { $0.text.count < $1.text.count }), longest.text.count > widestChange.text.count {
        widestChange = longest
      }
    }

    let axis = (chart.plotSeries.isEmpty
      ? PriceChartStyle.fallbackPriceAxis
      : PriceChartStyle.priceAxis(for: chart.priceRange)
    ).labeled(currencyCode: currency)

    return PriceHistoryDisplay(
      status: status,
      currencyCode: currency,
      summary: summary,
      statsTitles: [labels.finishes, labels.low, labels.high, labels.buylist, labels.spread],
      statsColumns: columns,
      statsRows: rows,
      chart: chart,
      axis: axis,
      scrubFrames: frames,
      widestPriceText: widestPrice,
      widestChange: widestChange,
      retailQuotes: status == .loaded ? section.retailQuotes : [:]
    )
  }

  static func finishes(of card: Card, charted: [PriceSeriesKind]) -> [PriceSeriesKind] {
    var kinds = Set(card.finishes.compactMap { finish -> PriceSeriesKind? in
      switch finish {
      case .nonfoil: .normal
      case .foil, .glossy: .foil
      case .etched: .etched
      case .unknown: nil
      }
    })
    kinds.formUnion(charted)

    if kinds.isEmpty {
      kinds = Set(PriceSeriesKind.allCases.filter { PriceHistorySection.scryfallQuote(card: card, kind: $0) != nil })
    }
    if kinds.isEmpty {
      kinds = [.normal]
    }
    return PriceChartStyle.displayOrder.filter(kinds.contains)
  }

  private static func change(_ change: PriceChange?) -> Change? {
    guard let change else { return nil }
    return Change(text: PriceChartStyle.changeText(for: change), direction: PriceChartStyle.direction(for: change))
  }
}
