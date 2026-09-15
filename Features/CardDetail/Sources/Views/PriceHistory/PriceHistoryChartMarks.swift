import Charts
import Networking
import SwiftUI

struct PriceHistoryChartMarks: View {
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

  /// A solid hairline; Swift Charts would otherwise pick its own width and dash for each axis.
  private var gridStroke: StrokeStyle {
    StrokeStyle(lineWidth: 1.0 / max(displayScale, 1.0), dash: [])
  }

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
    .chartXScale(domain: derivedData.plotDateRange)
    .chartYAxis {
      AxisMarks(position: .trailing, values: axis.ticks) { value in
        AxisGridLine(stroke: gridStroke)
          .foregroundStyle(PriceChartStyle.gridColor(colorScheme))

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
