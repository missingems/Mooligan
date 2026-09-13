import Networking
import SwiftUI

struct PriceHistoryHeaderView: View {
  let title: String
  let currencyCode: String
  let isLoading: Bool
  let derivedData: ChartDerivedData
  let interaction: ChartInteraction
  @Binding var summaryTop: CGFloat

  @Environment(\.displayScale) private var displayScale

  private static let columnSpacing: CGFloat = 13.0
  private static let tightColumnSpacing: CGFloat = 10.0

  var body: some View {
    VStack(alignment: .leading, spacing: 8.0) {
      Text(title).font(.headline)
      summary
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .overlay(alignment: .topTrailing) {
      if isLoading {
        ProgressView()
      }
    }
  }

  private var isScrubbing: Bool { interaction.scrubbedDate != nil }

  private var summary: some View {
    ProposedWidthLayout {
      VStack(alignment: .leading, spacing: 5.0) {
        ViewThatFits(in: .horizontal) {
          columns(spacing: Self.columnSpacing)
          columns(spacing: Self.tightColumnSpacing)
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
          geometry.frame(in: .named(ScrubLayout.space)).minY.snapped(to: displayScale)
        } action: { top in
          if summaryTop != top { summaryTop = top }
        }
      }
    }
    .opacity(isScrubbing ? 0.35 : 1.0)
    .saturation(isScrubbing ? 0.0 : 1.0)
    .animation(ScrubLayout.slide, value: isScrubbing)
    .transaction { $0.animation = $0.animation == ScrubLayout.slide ? $0.animation : nil }
    .accessibilityElement(children: .combine)
  }

  private func columns(spacing: CGFloat) -> some View {
    HStack(alignment: .top, spacing: spacing) {
      if derivedData.series.isEmpty {
        ForEach(PriceChartStyle.displayOrder, id: \.self) { kind in
          column(kind: kind, readout: nil)
        }
      }

      ForEach(derivedData.series) { series in
        column(kind: series.kind, readout: series.latestReadout)
      }
    }
    .lineLimit(1)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func column(kind: PriceSeriesKind, readout: PriceReadout?) -> some View {
    VStack(alignment: .leading, spacing: 3.0) {
      HStack(alignment: .center, spacing: 5.0) {
        ZStack(alignment: .leading) {
          PriceChangePill(change: nil)
            .frame(width: 0.0, alignment: .leading)
            .hidden()

          Group {
            if let readout {
              Text(readout.point.amount, format: PriceChartStyle.price(currencyCode))
            } else {
              Text(PriceChartStyle.missingValue)
            }
          }
          .font(.body)
          .fontWeight(.medium)
          .monospaced()
        }

        if let change = readout?.change {
          PriceChangePill(change: change)
            .monospacedDigit()
            .fixedSize()
        }
      }
      
      HStack(spacing: 5.0) {
        FinishSwatch(kind: kind)
        
        Text(PriceChartStyle.label(for: kind))
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }
    }
  }
}

struct ProposedWidthLayout: Layout {
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let width = proposal.width ?? 0.0
    let height = subviews.first?.sizeThatFits(ProposedViewSize(width: width, height: nil)).height ?? 0.0
    return CGSize(width: width, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    subviews.first?.place(
      at: bounds.origin,
      proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
    )
  }
}

extension CGFloat {
  func snapped(to scale: CGFloat) -> CGFloat {
    guard scale > 0.0, isFinite else { return self }
    return (self * scale).rounded() / scale
  }
}

extension CGSize {
  func snapped(to scale: CGFloat) -> CGSize {
    CGSize(width: width.snapped(to: scale), height: height.snapped(to: scale))
  }
}

extension CGPoint {
  func snapped(to scale: CGFloat) -> CGPoint {
    CGPoint(x: x.snapped(to: scale), y: y.snapped(to: scale))
  }
}
