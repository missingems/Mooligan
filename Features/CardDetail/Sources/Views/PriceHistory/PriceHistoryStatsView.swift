import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryStatsView: View {
  let titles: [String]
  let columns: [PriceHistoryDisplay.StatsColumn]
  let rows: [PriceHistoryDisplay.StatsRow]

  var body: some View {
    VStack(spacing: 3.0) {
      header

      ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
        cells(row)
          .background {
            if index.isMultiple(of: 2) {
              RoundedRectangle(cornerRadius: 8.0).fill(Color(.tertiarySystemFill))
            }
          }
      }
    }
    .font(.caption)
    .lineLimit(1)
  }

  private var header: some View {
    HStack(spacing: 8.0) {
      titleCell(titles.first ?? "")

      ForEach(columns) { column in
        HStack(spacing: 4.0) {
          FinishSwatch(kind: column.kind)

          Text(column.label)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .opacity(column.isAvailable ? 1.0 : 0.3)
      }
    }
    .padding(.horizontal, 8.0)
    .padding(.vertical, 5.0)
  }

  private func cells(_ row: PriceHistoryDisplay.StatsRow) -> some View {
    HStack(spacing: 8.0) {
      titleCell(row.title)

      ForEach(Array(zip(columns, row.values)), id: \.0.id) { column, value in
        // A fixed stand-in sizes the cell and the value sits over it, so values landing change
        // what is drawn without changing the layout around the table.
        Text(PriceChartStyle.missingValue)
          .monospaced()
          .hidden()
          .frame(maxWidth: .infinity, alignment: .trailing)
          .overlay(alignment: .trailing) {
            Text(value)
              .monospaced()
              .id(value)
              .transition(.opacity)
          }
          .opacity(column.isAvailable ? 1.0 : 0.3)
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
}
