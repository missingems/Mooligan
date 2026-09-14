import DesignComponents
import Networking
import SwiftUI

struct PriceHistoryView: View {
  private let display: PriceHistoryDisplay
  private let purchaseDropdown: PurchaseDropdownState
  private let labels: PriceHistoryLabels
  private let onRetry: () -> Void
  private let onPurchaseLinksRequested: () -> Void

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale
  @Environment(\.openURL) private var openURL

  @State private var interaction = ChartInteraction()
  @State private var layout = ScrubLayout()
  @State private var isPurchaseLinksPresented = false

  @Namespace private var purchaseGlass

  static let chartHeight: CGFloat = 233.0
  private static let stackSpacing: CGFloat = 8
  private static let chartGap: CGFloat = 13.0
  private static let purchaseGlassID = "priceHistory.purchase"
  private static let dropdownAnimation: Animation = .bouncy(duration: 0.35)
  private static let loadAnimation: Animation = .smooth(duration: 0.35)

  init(
    display: PriceHistoryDisplay,
    purchaseDropdown: PurchaseDropdownState,
    labels: PriceHistoryLabels,
    onRetry: @escaping () -> Void,
    onPurchaseLinksRequested: @escaping () -> Void
  ) {
    self.display = display
    self.purchaseDropdown = purchaseDropdown
    self.labels = labels
    self.onRetry = onRetry
    self.onPurchaseLinksRequested = onPurchaseLinksRequested
  }

  var body: some View {
    VibrantDivider()
      .safeAreaPadding(.leading, systemHorizontalMargin)

    VStack(alignment: .leading, spacing: 0.0) {
      PriceHistoryHeaderView(
        title: labels.title,
        summary: display.summary,
        interaction: interaction,
        summaryFrame: $layout.summaryFrame
      )
      .onGeometryChange(for: CGFloat.self) { [displayScale] in $0.size.width.snapped(to: displayScale) } action: { width in
        if layout.headerWidth != width { layout.headerWidth = width }
      }

      chartCard
        .padding(.top, Self.chartGap)

      PriceHistoryStatsView(
        titles: display.statsTitles,
        columns: display.statsColumns,
        rows: display.statsRows
      )
      .padding(.top, Self.stackSpacing)
    }
    .animation(Self.loadAnimation, value: display.status)
    .overlay(alignment: .topLeading) {
      PriceHistoryNeedle(
        interaction: interaction,
        isEnabled: display.hasChart,
        layout: layout
      )
    }
    .overlay(alignment: .topTrailing) { toolbar }
    .overlay(alignment: .topLeading) {
      PriceHistoryScrubReadout(
        display: display,
        interaction: interaction,
        isEnabled: display.hasChart,
        layout: layout,
        size: $layout.readoutSize
      )
    }
    .overlay { dismissArea }
    .coordinateSpace(.named(ScrubLayout.space))
    .onChange(of: display.chart) { interaction.endScrub() }
    .padding(.horizontal, systemHorizontalMargin)
    .padding(EdgeInsets(top: 13.0, leading: 0.0, bottom: 13.0, trailing: 0.0))
  }

  private var chartCard: some View {
    chartContent
      .frame(height: Self.chartHeight)
      .onGeometryChange(for: CGPoint.self) { [displayScale] geometry in
        geometry.frame(in: .named(ScrubLayout.space)).origin.snapped(to: displayScale)
      } action: { origin in
        if layout.chartOrigin != origin { layout.chartOrigin = origin }
      }
      .padding(.vertical, 13.0)
      .padding(.horizontal, 13.0)
      .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 21.0))
  }

  private var chartContent: some View {
    ZStack {
      if display.status == .loading {
        PriceHistoryChart(
          derivedData: display.chart,
          axis: display.axis,
          interaction: interaction,
          isLoading: true
        )
        .transition(.opacity)
      } else {
        PriceHistoryChart(
          derivedData: display.chart,
          axis: display.axis,
          interaction: interaction
        )
        .transition(.opacity)
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
  }

  private var toolbar: some View {
    GlassEffectContainer {
      ZStack(alignment: .topTrailing) {
        if isPurchaseLinksPresented {
          PriceHistoryPurchaseLinksView(
            state: purchaseDropdown,
            labels: labels,
            onRetry: onPurchaseLinksRequested,
            onSelect: { offer in
              closePurchaseLinks()
              openURL(offer.url)
            },
            glass: (Self.purchaseGlassID, purchaseGlass)
          )
        } else {
          GlassCapsuleAction(
            title: labels.purchase,
            systemImage: "cart",
            accessibilityID: "priceHistory.cart",
            action: openPurchaseLinks
          )
          .glassEffectID(Self.purchaseGlassID, in: purchaseGlass)
        }
      }
    }
  }

  @ViewBuilder private var dismissArea: some View {
    if isPurchaseLinksPresented {
      Color.clear
        .contentShape(.rect)
        .onTapGesture { closePurchaseLinks() }
        .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { old, new in
          if abs(new.y - old.y) > 1.0 || abs(new.x - old.x) > 1.0 {
            closePurchaseLinks()
          }
        }
        .accessibilityHidden(true)
    }
  }

  private func openPurchaseLinks() {
    onPurchaseLinksRequested()
    withAnimation(Self.dropdownAnimation) { isPurchaseLinksPresented = true }
  }

  private func closePurchaseLinks() {
    guard isPurchaseLinksPresented else { return }
    withAnimation(Self.dropdownAnimation) { isPurchaseLinksPresented = false }
  }
}
