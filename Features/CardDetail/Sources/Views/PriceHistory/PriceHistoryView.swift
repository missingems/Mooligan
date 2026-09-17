import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryView: View {
  private let display: PriceHistoryDisplay
  private let labels: PriceHistoryLabels
  private let onRetry: () -> Void

  @State private var interaction: ChartInteraction

  init(
    display: PriceHistoryDisplay,
    labels: PriceHistoryLabels,
    onRetry: @escaping () -> Void,
    interaction: ChartInteraction = ChartInteraction()
  ) {
    self.display = display
    self.labels = labels
    self.onRetry = onRetry
    _interaction = State(initialValue: interaction)
  }

  var body: some View {
    VibrantDivider()
      .padding(.leading, systemHorizontalMargin)

    VStack(alignment: .leading, spacing: 8.0) {
      VStack(alignment: .leading, spacing: 5.0) {
        Text(labels.title).font(.headline)
        Text(PriceChartStyle.spanText(of: display.chart.dateRange))
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      chart
        .frame(height: 233.0)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
          if interaction.chartSize != size { interaction.chartSize = size }
        }
        // The scrub readout lives in the chart's coordinate space and reaches over the title
        // above, so the chart draws over it.
        .overlay(alignment: .topLeading) {
          PriceHistoryScrubReadout(display: display, interaction: interaction, margin: systemHorizontalMargin)
        }
        .zIndex(1.0)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("priceHistory.chart")
        .padding(.top, 5.0)

      PriceHistoryToolbar(display: display, labels: labels)
        .padding(.top, 13.0)
    }
    .padding(.horizontal, systemHorizontalMargin)
    .padding(EdgeInsets(top: 13.0, leading: 0.0, bottom: 21.0, trailing: 0.0))
  }

  private var chart: some View {
    PriceHistoryChart(
      derivedData: display.chart,
      axis: display.axis,
      interaction: interaction
    )
    .overlay {
      switch display.status {
      case .unavailable:
        PriceHistoryEmptyMessage(reason: .unavailable, labels: labels, onRetry: onRetry)
      case .failed:
        PriceHistoryEmptyMessage(reason: .failed, labels: labels, onRetry: onRetry)
      case .loading, .loaded:
        EmptyView()
      }
    }
  }
}
