import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryView: View {
  private let state: PriceHistoryState
  private let title: String
  private let sourceLabel: String
  private let unavailableLabel: String

  @Environment(\.colorScheme) private var colorScheme

  @State private var isolatedKind: PriceSeriesKind?
  @State private var range: PriceHistoryRange = .quarter
  @State private var rangedFeed: ClosedRange<Date>?
  @State private var derivedData = ChartDerivedData()
  @State private var interaction = ChartInteraction()
  @State private var readoutOverhang: CGFloat = 0.0
  @State private var chartOpacity: Double = 0.0
  @State private var readoutOpacity: Double = 0.0
  private static let stackSpacing: CGFloat = 21

  init(
    state: PriceHistoryState,
    title: String,
    sourceLabel: String,
    unavailableLabel: String
  ) {
    self.state = state
    self.title = title
    self.sourceLabel = sourceLabel
    self.unavailableLabel = unavailableLabel
  }

  var body: some View {
    VibrantDivider()
      .safeAreaPadding(.leading, systemHorizontalMargin)

    VStack(alignment: .leading, spacing: Self.stackSpacing) {
      PriceHistoryHeaderView(
        title: title,
        placeholderSubtitle: placeholderSubtitle,
        currencyCode: currencyCode,
        isLoading: isLoading,
        readoutOpacity: readoutOpacity,
        derivedData: derivedData,
        interaction: interaction,
        availableRanges: availableRanges,
        range: $range,
        readoutOverhang: $readoutOverhang
      )

      PriceHistoryChart(
        derivedData: derivedData,
        interaction: interaction,
        currencyCode: currencyCode,
        needleOvershoot: needleOvershoot
      )
      .id(colorScheme)
      .opacity(chartOpacity)
      .frame(height: 233.0, alignment: .leading)
      .onChange(of: state, initial: true) { syncRange() }
      .task(id: derivationKey) { await deriveChartData() }
    }
    .padding(.horizontal, systemHorizontalMargin)
    .padding(.vertical, 13.0)
  }

  private var needleOvershoot: CGFloat {
    max(0.0, Self.stackSpacing - readoutOverhang)
  }

  private var isLoading: Bool {
    if case .loading = state { true } else { false }
  }

  private var currencyCode: String {
    if case let .data(section) = state { section.currency } else { "USD" }
  }

  private var placeholderSubtitle: String? {
    switch state {
    case .loading: sourceLabel
    case .unavailable: unavailableLabel
    case .data: nil
    }
  }

  private var fullSpanInDays: Int {
    PriceChartStyle.spanInDays(of: state.data.dateRange)
  }

  private var availableRanges: [PriceHistoryRange] {
    PriceHistoryRange.available(forSpanOfDays: fullSpanInDays)
  }

  private func syncRange() {
    let feed = state.data.dateRange
    guard rangedFeed != feed else { return }
    rangedFeed = feed
    range = PriceHistoryRange.widest(forSpanOfDays: fullSpanInDays)
  }

  private var derivationKey: DerivationKey {
    let section = state.data
    return DerivationKey(
      isLoading: isLoading,
      dates: section.dateRange,
      prices: section.priceRange,
      kinds: section.series.map(\.kind),
      currency: section.currency,
      releases: section.releases.count,
      isolatedKind: isolatedKind,
      range: range
    )
  }

  private struct DerivationKey: Equatable {
    let isLoading: Bool
    let dates: ClosedRange<Date>
    let prices: ClosedRange<Double>
    let kinds: [PriceSeriesKind]
    let currency: String
    let releases: Int
    let isolatedKind: PriceSeriesKind?
    let range: PriceHistoryRange
  }

  private func deriveChartData() async {
    interaction.endScrub()

    let section = state.data
    let isolatedKind = isolatedKind
    let range = range

    let derived = await Task.detached(priority: .userInitiated) {
      ChartDerivedData(section: section, isolatedKind: isolatedKind, range: range)
    }.value

    guard Task.isCancelled == false else { return }

    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) { derivedData = derived }

    let chartTarget: Double = isLoading ? 0.0 : 1.0
    let readoutTarget: Double = derived.plotSeries.isEmpty ? 0.0 : 1.0
    guard chartOpacity != chartTarget || readoutOpacity != readoutTarget else { return }

    withAnimation(.easeOut(duration: 0.25)) {
      chartOpacity = chartTarget
      readoutOpacity = readoutTarget
    }
  }
}
