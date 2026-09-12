import Networking
import SwiftUI

struct PriceHistoryHeaderView: View {
  let title: String
  let placeholderSubtitle: String?
  let currencyCode: String
  let isLoading: Bool
  let readoutOpacity: Double
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  let availableRanges: [PriceHistoryRange]
  @Binding var range: PriceHistoryRange
  @Binding var readoutOverhang: CGFloat

  @State private var rowSize: CGSize = .zero
  @State private var readoutSize: CGSize = .zero

  private static let readoutDrop: CGFloat = 13.0

  private static let subtitleHeight: CGFloat = 22.0

  var body: some View {
    HStack(alignment: .top, spacing: 8.0) {
      VStack(alignment: .leading, spacing: 5.0) {
        Text(title)
          .font(.headline)
          .lineLimit(1)

        Group {
          if let placeholderSubtitle {
            Text(placeholderSubtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          } else {
            rangeMenu
          }
        }
        .frame(height: Self.subtitleHeight, alignment: .topLeading)
      }

      Spacer(minLength: 0.0)

      if isLoading {
        ProgressView()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onGeometryChange(for: CGSize.self) { $0.size } action: { rowSize = $0 }
    .overlay(alignment: .topTrailing) {
      readout
        .onGeometryChange(for: CGSize.self) { $0.size } action: { readoutSize = $0 }
        .offset(x: readoutOffset, y: Self.readoutDrop)
        .opacity(readoutOpacity)
    }
    .onChange(of: overhang, initial: true) { readoutOverhang = overhang }
    .animation(.snappy(duration: 0.22), value: isScrubbing)
    .accessibilityElement(children: .combine)
    .zIndex(100)
  }

  private var isScrubbing: Bool { interaction.scrubbedDate != nil }

  private var overhang: CGFloat {
    guard readoutOpacity > 0.0 else { return 0.0 }
    return Self.readoutDrop + readoutSize.height - rowSize.height
  }

  private var readoutOffset: CGFloat {
    guard let needleX = interaction.needleX, rowSize.width > 0.0, readoutSize.width > 0.0 else {
      return 0.0
    }
    let resting = rowSize.width - readoutSize.width
    let centred = min(max(needleX - readoutSize.width / 2.0, 0.0), max(resting, 0.0))
    return centred - resting
  }

  private var rangeMenu: some View {
    Menu {
      Picker(selection: $range) {
        ForEach(availableRanges) { option in
          Text(option.label).tag(option)
        }
      } label: {
        EmptyView()
      }
      .pickerStyle(.inline)
    } label: {
      HStack(spacing: 2.0) {
        Text(range.label)
        Image(systemName: "chevron.up.chevron.down")
          .font(.caption2)
      }
      .font(.caption)
      .lineLimit(1)
    }
    .menuStyle(.button)
    .buttonStyle(.plain)
    .foregroundStyle(.secondary)
    .accessibilityLabel(Text("Date range"))
  }

  @ViewBuilder private var readout: some View {
    VStack(alignment: .trailing, spacing: 3.0) {
      priceGrid
    }
    .animation(isScrubbing ? .snappy(duration: 0.18) : nil, value: readoutDay)
    .lineLimit(1)
    .fixedSize()
    .padding(.horizontal, 13)
    .padding(.vertical, 11)
    .glassEffect(.regular, in: RoundedRectangle(cornerSize: CGSize(width: 21, height: 21)))
  }

  private var readoutDay: Date? {
    derivedData.anchorSeries.flatMap { interaction.readout(for: $0)?.point.date }
  }

  @ViewBuilder private var priceGrid: some View {
    Grid(alignment: .trailing, horizontalSpacing: 5.0, verticalSpacing: 2.0) {
      ForEach(derivedData.displayedSeries) { series in
        if let readout = interaction.readout(for: series) {
          GridRow {
            Circle()
              .fill(PriceChartStyle.color(for: series.kind))
              .frame(width: 3, height: 3)

            Text(readout.point.amount, format: PriceChartStyle.price(currencyCode))
              .font(Self.priceFont)
              .monospacedDigit()
              .contentTransition(.numericText())

            changeCell(readout.change)
          }
        }
      }
    }
  }

  private static let priceFont: Font = .subheadline

  private static let changeFont: Font = .footnote

  private func changeCell(_ change: PriceChange?) -> some View {
    changeLabel(change)
      .font(Self.changeFont.monospacedDigit())
      .foregroundStyle(PriceChartStyle.trendColor(change))
      .contentTransition(.numericText())
      .gridColumnAlignment(.leading)
  }

  private func changeLabel(_ change: PriceChange?) -> Text {
    guard let change else { return Text(verbatim: "") }
    let magnitude = PriceChartStyle.changeText(for: change)
    guard let symbol = PriceChartStyle.changeSymbol(for: change) else { return Text(magnitude) }
    return Text("\(Image(systemName: symbol))\(magnitude)")
  }
}
