import Charts
import Networking
import SwiftUI

struct PriceHistoryChart: View {
  let derivedData: ChartDerivedData
  let axis: PriceChartStyle.PriceAxis
  let interaction: ChartInteraction
  var isLoading = false

  var body: some View {
    let scale = PlotScale(plot: interaction.plot, dates: derivedData.dateRange, prices: axis.domain)

    PriceHistoryChartMarks(derivedData: derivedData, axis: axis, interaction: interaction)
      .background {
        let tickRows = axis.ticks.compactMap(scale.y(for:))
        if isLoading {
          PriceHistoryLoadingDotMatrix(plot: scale.plot, tickRows: tickRows)
        } else {
          PriceHistoryDotMatrix(plot: scale.plot, tickRows: tickRows)
        }
      }
      .overlay {
        if scale.isMeasured {
          PriceHistoryChartOverlay(derivedData: derivedData, interaction: interaction, scale: scale)
        }
      }
      .coordinateSpace(.named(PlotScale.space))
  }
}

private struct PriceHistoryChartMarks: View {
  private struct LinePoint {
    let series: String
    let date: Date
    let value: Double
  }

  private struct AreaPoint {
    let date: Date
    let floor: Double
    let value: Double
  }

  let derivedData: ChartDerivedData
  let axis: PriceChartStyle.PriceAxis
  let interaction: ChartInteraction

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale

  var body: some View {
    let domain = axis.domain
    
    Chart {
      ForEach(derivedData.plotSeries) { series in
        let color = PriceChartStyle.color(for: series.kind)

        if derivedData.plotSeries.count == 1 {
          AreaPlot(
            series.points.map { AreaPoint(date: $0.date, floor: domain.lowerBound, value: $0.value) },
            x: .value("Date", \.date),
            yStart: .value("Floor", \.floor),
            yEnd: .value("Price", \.value)
          )
          .interpolationMethod(.monotone)
          .foregroundStyle(
            .linearGradient(
              colors: [color.opacity(0.26), color.opacity(0.0)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
        }

        // Without a series value, consecutive line plots are joined into a single line.
        LinePlot(
          series.points.map { LinePoint(series: series.id, date: $0.date, value: $0.value) },
          x: .value("Date", \.date),
          y: .value("Price", \.value),
          series: .value("ID", \.series)
        )
        .interpolationMethod(.monotone)
        .foregroundStyle(color)
      }
    }
    .chartLegend(.hidden)
    .chartYScale(domain: domain)
    .chartXScale(domain: derivedData.dateRange)
    .chartYAxis {
      AxisMarks(position: .trailing, values: axis.ticks) { value in
        AxisValueLabel(anchor: .leading) {
          Text(axis.label(at: value.index))
            .font(.caption2)
            .monospaced()
            .foregroundStyle(PriceChartStyle.vibrantLabelColor(colorScheme))
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic(desiredCount: 3)) { value in
        AxisValueLabel(anchor: .top) {
          if let date = value.as(Date.self) {
            Text(date, format: PriceChartStyle.axisDateStyle(forDays: derivedData.spanInDays))
              .font(.caption2)
              .foregroundStyle(PriceChartStyle.vibrantLabelColor(colorScheme))
          }
        }
      }
    }
    .chartPlotStyle { plotArea in
      plotArea.onGeometryChange(for: CGRect.self) { [displayScale] geometry in
        PlotScale.drawable(geometry.frame(in: .named(PlotScale.space)), snappedTo: displayScale)
      } action: { rect in
        guard rect != .zero, interaction.plot != rect else { return }
        interaction.plot = rect
      }
    }
  }
}

struct PlotScale: Equatable {
  static let space = "PriceHistory.chart"

  let plot: CGRect
  let dates: ClosedRange<Date>
  let prices: ClosedRange<Double>

  var isMeasured: Bool { plot.width > 0.0 && plot.height > 0.0 }

  func x(for date: Date) -> CGFloat? {
    let span = dates.upperBound.timeIntervalSince(dates.lowerBound)
    guard isMeasured, span > 0.0 else { return nil }
    let x = plot.minX + CGFloat(date.timeIntervalSince(dates.lowerBound) / span) * plot.width
    return x.isFinite ? x : nil
  }

  func y(for price: Double) -> CGFloat? {
    let span = prices.upperBound - prices.lowerBound
    guard isMeasured, span > 0.0 else { return nil }
    let y = plot.maxY - CGFloat((price - prices.lowerBound) / span) * plot.height
    return y.isFinite ? y : nil
  }

  func date(atX x: CGFloat) -> Date? {
    guard isMeasured else { return nil }
    let fraction = Double((min(max(x, plot.minX), plot.maxX) - plot.minX) / plot.width)
    return dates.lowerBound.addingTimeInterval(fraction * dates.upperBound.timeIntervalSince(dates.lowerBound))
  }

  static func drawable(_ rect: CGRect, snappedTo displayScale: CGFloat) -> CGRect {
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
    return CGRect(
      origin: normalized.origin.snapped(to: displayScale),
      size: normalized.size.snapped(to: displayScale)
    )
  }
}
