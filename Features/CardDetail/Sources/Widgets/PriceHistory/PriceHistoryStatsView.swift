import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryStatsView: View {
  let derivedData: ChartDerivedData
  let currencyCode: String
  let finishesLabel: String
  let lowLabel: String
  let highLabel: String
  let spreadLabel: String
  let buylistLabel: String

  private static let finishes = PriceChartStyle.displayOrder
  private static let missing = PriceChartStyle.missingValue

  private struct Row {
    let title: String
    let values: [String]
  }

  var body: some View {
    VStack(spacing: 3.0) {
      header

      ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
        cells(row)
          .background {
            if index.isMultiple(of: 2) {
              RoundedRectangle(cornerRadius: 8.0).fill(Color(.tertiarySystemFill))
            }
          }
      }
    }
    .font(.caption)
    .fontWeight(.medium)
    .lineLimit(1)
  }

  private var header: some View {
    HStack(spacing: 8.0) {
      titleCell(finishesLabel)

      ForEach(Self.finishes, id: \.self) { kind in
        HStack(spacing: 4.0) {
          FinishSwatch(kind: kind)

          Text(PriceChartStyle.label(for: kind))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .opacity(emphasis(kind))
      }
    }
    .padding(.horizontal, 8.0)
    .padding(.vertical, 5.0)
  }

  private func cells(_ row: Row) -> some View {
    HStack(spacing: 8.0) {
      titleCell(row.title)

      ForEach(Array(zip(Self.finishes, row.values)), id: \.0) { kind, value in
        Text(value)
          .monospaced()
          .frame(maxWidth: .infinity, alignment: .trailing)
          .opacity(emphasis(kind))
      }
    }
    .padding(.horizontal, 8.0)
    .padding(.vertical, 5.0)
  }

  private func titleCell(_ title: String) -> some View {
    ZStack(alignment: .leading) {
      ForEach(titles, id: \.self) { Text($0).hidden() }
      Text(title)
    }
    .fixedSize()
  }

  private var titles: [String] {
    [finishesLabel, lowLabel, highLabel, buylistLabel, spreadLabel]
  }

  private var rows: [Row] {
    [
      Row(title: lowLabel, values: Self.finishes.map { kind in
        derivedData.range(for: kind).map { format($0.lowerBound) } ?? Self.missing
      }),
      Row(title: highLabel, values: Self.finishes.map { kind in
        derivedData.range(for: kind).map { format($0.upperBound) } ?? Self.missing
      }),
      Row(title: buylistLabel, values: Self.finishes.map { kind in
        derivedData.buylist(for: kind).map(format) ?? Self.missing
      }),
      Row(title: spreadLabel, values: Self.finishes.map { kind in
        derivedData.spread(for: kind)
          .map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? Self.missing
      }),
    ]
  }

  private func emphasis(_ kind: PriceSeriesKind) -> Double {
    guard derivedData.series.isEmpty == false else { return 1.0 }
    return derivedData.isAvailable(kind) ? 1.0 : 0.3
  }

  private func format(_ amount: Decimal) -> String {
    amount.formatted(PriceChartStyle.price(currencyCode))
  }
}
