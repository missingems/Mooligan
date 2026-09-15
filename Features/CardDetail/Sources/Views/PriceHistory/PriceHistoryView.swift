import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryView: View {
  private let display: PriceHistoryDisplay
  private let labels: PriceHistoryLabels
  private let onRetry: () -> Void

  @State private var interaction = ChartInteraction()

  static let chartHeight: CGFloat = 167
  private static let loadAnimation: Animation = .smooth(duration: 0.45)

  init(
    display: PriceHistoryDisplay,
    labels: PriceHistoryLabels,
    onRetry: @escaping () -> Void
  ) {
    self.display = display
    self.labels = labels
    self.onRetry = onRetry
  }

  var body: some View {
    VibrantDivider()
      .safeAreaPadding(.leading, systemHorizontalMargin)

    VStack(alignment: .leading, spacing: 8.0) {
      Text(labels.title).font(.headline)

      PriceHistoryToolbar(display: display, labels: labels, interaction: interaction)
        // Above the chart, so the buy back breakdown grows over it.
        .zIndex(1.0)

      chart
        .frame(height: Self.chartHeight)
        .padding(.top, 13.0)
    }
    // Landing prices animate in: the toolbar's numbers roll and the chart eases to its new lines and axis.
    .animation(Self.loadAnimation, value: display)
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
