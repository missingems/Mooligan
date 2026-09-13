import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryView: View {
  private let state: PriceHistoryState
  private let title: String
  private let finishesLabel: String
  private let lowLabel: String
  private let highLabel: String
  private let spreadLabel: String
  private let buylistLabel: String
  private let unavailableLabel: String

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale

  @State private var derivedData = ChartDerivedData()
  @State private var interaction = ChartInteraction()
  @State private var chartOpacity: Double = 0.0
  @State private var isUnavailable = false
  @State private var layout = ScrubLayout()

  private static let stackSpacing: CGFloat = 8
  private static let chartGap: CGFloat = 13.0

  init(
    state: PriceHistoryState,
    title: String,
    finishesLabel: String,
    lowLabel: String,
    highLabel: String,
    spreadLabel: String,
    buylistLabel: String,
    unavailableLabel: String
  ) {
    self.state = state
    self.title = title
    self.finishesLabel = finishesLabel
    self.lowLabel = lowLabel
    self.highLabel = highLabel
    self.spreadLabel = spreadLabel
    self.buylistLabel = buylistLabel
    self.unavailableLabel = unavailableLabel
  }

  var body: some View {
    VibrantDivider()
      .safeAreaPadding(.leading, systemHorizontalMargin)

    VStack(alignment: .leading, spacing: 0.0) {
      PriceHistoryHeaderView(
        title: title,
        currencyCode: currencyCode,
        isLoading: isLoading,
        derivedData: derivedData,
        interaction: interaction,
        summaryTop: $layout.summaryTop
      )
      .onGeometryChange(for: CGFloat.self) { $0.size.width.snapped(to: displayScale) } action: { width in
        if layout.headerWidth != width { layout.headerWidth = width }
      }

      PriceHistoryChart(
        derivedData: derivedData,
        interaction: interaction,
        currencyCode: currencyCode
      )
      .id(colorScheme)
      .opacity(chartOpacity)
      .overlay {
        if isUnavailable {
          Text(unavailableLabel)
            .font(.title)
            .foregroundStyle(.secondary)
            .allowsHitTesting(false)
        }
      }
      .frame(height: 233.0, alignment: .leading)
      .onGeometryChange(for: CGPoint.self) { geometry in
        geometry.frame(in: .named(ScrubLayout.space)).origin.snapped(to: displayScale)
      } action: { origin in
        if layout.chartOrigin != origin { layout.chartOrigin = origin }
      }
      .padding(.vertical, 13.00)
      .padding(.horizontal, 5.0)
      .background(
        Color(.tertiarySystemFill),
        in: RoundedRectangle(cornerRadius: PriceChartStyle.cardCornerRadius)
      )
      .overlay {
        RoundedRectangle(cornerRadius: PriceChartStyle.cardCornerRadius)
          .strokeBorder(PriceChartStyle.gridColor(colorScheme), lineWidth: 1.0 / displayScale)
      }
      .padding(.top, Self.chartGap)

      PriceHistoryStatsView(
        derivedData: derivedData,
        currencyCode: currencyCode,
        finishesLabel: finishesLabel,
        lowLabel: lowLabel,
        highLabel: highLabel,
        spreadLabel: spreadLabel,
        buylistLabel: buylistLabel
      )
      .padding(.top, Self.stackSpacing)
      .transaction { transaction in
        transaction.animation = nil
      }
    }
    .background(alignment: .topLeading) {
      PriceHistoryNeedle(
        interaction: interaction,
        isEnabled: hasData,
        layout: layout
      )
    }
    .overlay(alignment: .topLeading) {
      PriceHistoryScrubReadout(
        derivedData: derivedData,
        interaction: interaction,
        currencyCode: currencyCode,
        isEnabled: hasData,
        layout: layout,
        size: $layout.readoutSize
      )
    }
    .coordinateSpace(.named(ScrubLayout.space))
    .padding(.horizontal, systemHorizontalMargin)
    .padding(EdgeInsets(top: 13.0, leading: 0.0, bottom: 18.0, trailing: 0.0))
    .task(id: derivationKey) { await deriveChartData() }
  }

  private var hasData: Bool {
    derivedData.plotSeries.isEmpty == false
  }

  private var isLoading: Bool {
    if case .loading = state { true } else { false }
  }

  private var currencyCode: String {
    if case let .data(section) = state { section.currency } else { "USD" }
  }

  private var derivationKey: DerivationKey {
    let section = state.data
    return DerivationKey(
      isLoading: isLoading,
      dates: section.dateRange,
      prices: section.priceRange,
      kinds: section.series.map(\.kind),
      currency: section.currency,
      releases: section.releases.count
    )
  }

  private struct DerivationKey: Equatable {
    let isLoading: Bool
    let dates: ClosedRange<Date>
    let prices: ClosedRange<Double>
    let kinds: [PriceSeriesKind]
    let currency: String
    let releases: Int
  }

  private func deriveChartData() async {
    interaction.endScrub()

    let section = state.data
    let isLoading = isLoading

    let derived = await Task.detached(priority: .userInitiated) {
      ChartDerivedData(section: section)
    }.value

    guard Task.isCancelled == false else { return }

    var transaction = Transaction()
    transaction.disablesAnimations = true

    if derivedData.plotSeries.isEmpty, derived.plotSeries.isEmpty == false {
      withAnimation(.easeInOut(duration: 0.3)) { derivedData = derived }
    } else {
      withTransaction(transaction) { derivedData = derived }
    }

    let unavailable = isLoading == false && derived.plotSeries.isEmpty
    if isUnavailable != unavailable {
      withTransaction(transaction) { isUnavailable = unavailable }
    }

    if chartOpacity != 1.0 {
      withAnimation(.easeOut(duration: 0.25)) { chartOpacity = 1.0 }
    }
  }
}
