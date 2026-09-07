import Charts
import ComposableArchitecture
import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

/// Price history for the card currently on screen, drawn from MTGGraphQL.
///
/// Renders nothing at all when there is no usable history — MTGJSON only retains
/// a few months and many printings have never been priced, so an empty chart
/// frame would be a worse outcome than simply omitting the section.
struct PriceHistoryChartView: View {
  private let card: Card
  private let title: String
  private let subtitle: String

  @Dependency(\.priceHistoryClient) private var client

  @State private var history: PriceHistory?
  @State private var kind: PriceSeriesKind = .normal
  @State private var isLoading = true
  @State private var selectedDate: Date?

  init(card: Card, title: String, subtitle: String) {
    self.card = card
    self.title = title
    self.subtitle = subtitle
  }

  private var points: [PricePoint] {
    history?.series[kind] ?? []
  }

  private var availableKinds: [PriceSeriesKind] {
    history?.chartableKinds ?? []
  }

  private var selectedPoint: PricePoint? {
    guard let selectedDate else { return nil }
    return points.min {
      abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
    }
  }

  var body: some View {
    if isLoading {
      loadingPlaceholder.task { await load() }
    } else if points.count >= 2 {
      content
    }
  }

  private var loadingPlaceholder: some View {
    Color.clear.frame(height: 0)
  }

  private var content: some View {
    Group {
      VibrantDivider()
        .safeAreaPadding(.leading, systemHorizontalMargin)

      VStack(alignment: .leading, spacing: 5.0) {
        HStack(alignment: .firstTextBaseline) {
          Text(title)
            .font(.headline)

          Spacer()

          if let point = selectedPoint ?? points.last {
            Text(point.amount, format: .currency(code: history?.currency ?? "USD"))
              .font(.subheadline)
              .fontWeight(.semibold)
              .monospaced()
              .contentTransition(.numericText())
          }
        }

        Text(selectedPoint.map { $0.date.formatted(date: .abbreviated, time: .omitted) } ?? subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)

        chart
          .frame(height: 160)
          .padding(.top, 8.0)

        if availableKinds.count > 1 {
          Picker("", selection: $kind) {
            ForEach(availableKinds) { kind in
              Text(label(for: kind)).tag(kind)
            }
          }
          .pickerStyle(.segmented)
          .padding(.top, 3.0)
        }
      }
      .safeAreaPadding(.horizontal, systemHorizontalMargin)
      .padding(.vertical, 13.0)
      .animation(.default, value: kind)
    }
  }

  private var chart: some View {
    Chart {
      ForEach(points) { point in
        LineMark(
          x: .value("Date", point.date),
          y: .value("Price", point.amount.doubleValue)
        )
        .interpolationMethod(.monotone)
        .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)

        AreaMark(
          x: .value("Date", point.date),
          y: .value("Price", point.amount.doubleValue)
        )
        .interpolationMethod(.monotone)
        .foregroundStyle(
          .linearGradient(
            colors: [
              DesignComponentsAsset.accentColor.swiftUIColor.opacity(0.28),
              DesignComponentsAsset.accentColor.swiftUIColor.opacity(0.0),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
      }

      if let selectedPoint {
        RuleMark(x: .value("Date", selectedPoint.date))
          .foregroundStyle(.secondary.opacity(0.4))
          .lineStyle(StrokeStyle(lineWidth: 1))

        PointMark(
          x: .value("Date", selectedPoint.date),
          y: .value("Price", selectedPoint.amount.doubleValue)
        )
        .foregroundStyle(DesignComponentsAsset.accentColor.swiftUIColor)
        .symbolSize(60)
      }
    }
    .chartXSelection(value: $selectedDate)
    .chartYScale(domain: .automatic(includesZero: false))
    .chartYAxis {
      AxisMarks(position: .leading) { value in
        AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
        AxisValueLabel {
          if let amount = value.as(Double.self) {
            Text(amount, format: .number.precision(.fractionLength(0)))
              .font(.caption2)
          }
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .stride(by: .month)) { value in
        AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
        AxisValueLabel(format: .dateTime.month(.abbreviated))
      }
    }
  }

  private func label(for kind: PriceSeriesKind) -> String {
    switch kind {
    case .normal: "Normal"
    case .foil: "Foil"
    case .etched: "Etched"
    }
  }

  private func load() async {
    defer { isLoading = false }
    // A missing proxy URL, a rate limit, or a card MTGJSON has never priced all
    // land here; every one of them means "draw nothing", so they share a path.
    guard let loaded = try? await client.history(for: card) else { return }
    history = loaded
    if loaded.chartableKinds.contains(kind) == false, let first = loaded.chartableKinds.first {
      kind = first
    }
  }
}

private extension Decimal {
  var doubleValue: Double { (self as NSDecimalNumber).doubleValue }
}
