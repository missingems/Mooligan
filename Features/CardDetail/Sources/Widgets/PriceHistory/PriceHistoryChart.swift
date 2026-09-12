import Charts
import Networking
import SwiftUI

struct PriceHistoryChart: View {
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  let currencyCode: String
  let needleOvershoot: CGFloat

  @Environment(\.colorScheme) private var colorScheme

  @State private var plot: CGRect = .zero

  var body: some View {
    let domain = yDomain(for: derivedData.priceRange)
    let fractionDigits = derivedData.priceRange.upperBound < 10 ? 2 : 0

    Chart {
      ForEach(derivedData.plotSeries) { series in
        let seriesLabel = PriceChartStyle.label(for: series.kind)

        ForEach(series.points) { point in
          LineMark(
            x: .value("Date", point.date),
            y: .value("Price", point.value),
            series: .value("ID", series.id)
          )
          .interpolationMethod(.monotone)
          .foregroundStyle(by: .value("Finish", seriesLabel))

          if derivedData.plotSeries.count == 1 {
            AreaMark(
              x: .value("Date", point.date),
              yStart: .value("Floor", domain.lowerBound),
              yEnd: .value("Price", point.value),
              series: .value("ID", series.id)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(
              .linearGradient(
                colors: [
                  PriceChartStyle.color(for: series.kind).opacity(0.26),
                  PriceChartStyle.color(for: series.kind).opacity(0.0),
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
          }
        }
      }
    }
    .chartForegroundStyleScale(
      domain: derivedData.plotSeries.map { PriceChartStyle.label(for: $0.kind) },
      range: derivedData.plotSeries.map { PriceChartStyle.color(for: $0.kind) }
    )
    .chartLegend(position: .bottom, alignment: .leading, spacing: 16)
    .chartYScale(domain: domain)
    .chartXScale(domain: derivedData.dateRange)
    .chartYAxis {
      AxisMarks(position: .trailing, values: .automatic) { value in
        AxisGridLine().foregroundStyle(PriceChartStyle.gridColor(colorScheme))

        AxisValueLabel(anchor: .leading) {
          if let amount = value.as(Double.self) {
            Text(amount, format: PriceChartStyle.axisPrice(currencyCode, fractionDigits: fractionDigits))
              .font(.caption2)
          }
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic(desiredCount: 3)) { _ in
        AxisGridLine().foregroundStyle(PriceChartStyle.gridColor(colorScheme))

        AxisValueLabel(
          format: PriceChartStyle.axisDateStyle(forDays: derivedData.spanInDays),
          anchor: .top
        )
      }
    }
    .chartOverlay { proxy in
      let plotAnchor = proxy.plotFrame

      ZStack(alignment: .topLeading) {
        Color.clear
          .onGeometryChange(for: CGRect.self) { geometry in
            Self.drawable(plotAnchor.map { geometry[$0] } ?? .zero)
          } action: { plot = $0 }

        if plot.width > 0, plot.height > 0 {
          PriceHistoryChartOverlay(
            derivedData: derivedData,
            interaction: interaction,
            proxy: proxy,
            plot: plot,
            needleOvershoot: needleOvershoot
          )
        }
      }
    }
  }

  private nonisolated static func drawable(_ rect: CGRect) -> CGRect {
    let normalized = rect.standardized
    guard
      normalized.origin.x.isFinite,
      normalized.origin.y.isFinite,
      normalized.width.isFinite,
      normalized.height.isFinite,
      normalized.width > 0,
      normalized.height > 0
    else {
      return .zero
    }
    return normalized
  }

  private func yDomain(for prices: ClosedRange<Double>) -> ClosedRange<Double> {
    let low = prices.lowerBound
    let high = prices.upperBound
    guard low.isFinite, high.isFinite else { return 0.0...1.0 }

    let span = high - low
    let padding = span > 0 ? span * 0.12 : max(abs(high) * 0.1, 0.05)
    let lower = max(0.0, low - padding)
    let upper = high + padding * 2.5
    guard lower.isFinite, upper.isFinite, upper > lower else { return 0.0...1.0 }
    return lower...upper
  }
}
