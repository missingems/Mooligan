import Charts
import DesignComponents
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

  var body: some View {
    let domain = axis.domain
    let ruleTop = releaseRuleTop(in: domain)

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

      // After the lines, so each release's rule draws over them. The set's icon sits at the top of
      // the plot, centred on its rule even when that puts half of it past the plot's edge, and the
      // rule starts 3 points under it.
      ForEach(derivedData.releases) { release in
        RuleMark(
          x: .value("Release", release.date),
          yStart: .value("Rule top", ruleTop),
          yEnd: .value("Rule bottom", domain.lowerBound)
        )
        .foregroundStyle(Color.primary.opacity(0.16))
        .lineStyle(StrokeStyle(lineWidth: 1.0 / max(displayScale, 1.0)))
        .annotation(
          position: .top,
          alignment: .center,
          spacing: 3.0,
          overflowResolution: .init(x: .disabled, y: .disabled)
        ) {
          IconLazyImage(release.iconURL, tintColor: .primary.opacity(0.67))
            .frame(width: 24.0, height: 24.0)
            .accessibilityLabel(Text(release.name))
        }
      }
    }
    .chartLegend(.hidden)
    .chartYScale(domain: domain)
    .chartXScale(domain: derivedData.dateRange)
    .chartYAxis {
      AxisMarks(position: .trailing, values: axis.ticks) { value in
        AxisGridLine(stroke: PriceChartStyle.gridStroke)
          .foregroundStyle(PriceChartStyle.gridColor(colorScheme))

        AxisValueLabel(anchor: .leading) {
          Text(axis.label(at: value.index))
            .font(.caption2)
            .fontDesign(.rounded)
            .compositingGroup()
            .foregroundStyle(PriceChartStyle.vibrantLabelTint(colorScheme))
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic(desiredCount: 3)) { value in
        AxisGridLine(stroke: PriceChartStyle.gridStroke)
          .foregroundStyle(PriceChartStyle.gridColor(colorScheme))

        AxisValueLabel(anchor: .top) {
          if let date = value.as(Date.self) {
            Text(date, format: PriceChartStyle.axisDateStyle(forDays: derivedData.spanInDays))
              .font(.caption2)
              .compositingGroup()
              .foregroundStyle(PriceChartStyle.vibrantLabelTint(colorScheme))
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

  /// Where a release's rule starts, as a price: the top of the plot less the 24-point icon and the
  /// 3 points either side of it. Until the plot is measured the rule runs the plot's full height.
  private func releaseRuleTop(in domain: ClosedRange<Double>) -> Double {
    let height = interaction.plot.height
    guard height > 0.0 else { return domain.upperBound }
    let span = domain.upperBound - domain.lowerBound
    return max(domain.upperBound - Double(30.0 / height) * span, domain.lowerBound)
  }
}
