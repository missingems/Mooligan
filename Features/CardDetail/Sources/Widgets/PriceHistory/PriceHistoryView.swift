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
    .background(alignment: .topLeading) {
      PriceHistoryNeedle(
        interaction: interaction,
        isEnabled: display.hasChart,
        layout: layout
      )
    }
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
    .overlay(alignment: .topTrailing) { toolbar }
    .coordinateSpace(.named(ScrubLayout.space))
    .onChange(of: display.chart) { interaction.endScrub() }
    .padding(.horizontal, systemHorizontalMargin)
    .padding(EdgeInsets(top: 13.0, leading: 0.0, bottom: 18.0, trailing: 0.0))
  }

  private var chartCard: some View {
    // The card's size comes from this fixed frame alone. The placeholder, chart and messages sit
    // in an overlay, which never feeds back into the size of the views around it, so swapping
    // one for another when prices land re-lays out only the card rather than the whole page.
    Color.clear
      .frame(height: Self.chartHeight)
      .overlay(alignment: .leading) { chartContent }
      .onGeometryChange(for: CGPoint.self) { [displayScale] geometry in
        geometry.frame(in: .named(ScrubLayout.space)).origin.snapped(to: displayScale)
      } action: { origin in
        if layout.chartOrigin != origin { layout.chartOrigin = origin }
      }
      .padding(.vertical, 13.0)
      .padding(.horizontal, 5.0)
      .background(
        LinearGradient(
          colors: [.clear, Color(.tertiarySystemFill)],
          startPoint: .top,
          endPoint: .bottom
        ),
        in: RoundedRectangle(cornerRadius: PriceChartStyle.cardCornerRadius)
      )
      .overlay {
        // A gradient fill masked to the stroke rather than a gradient-painted `strokeBorder`:
        // SwiftUI rasterizes a gradient stroke on the CPU into its own layer, which cost a few
        // milliseconds every time a card detail page was built.
        PriceChartStyle.borderGradient(colorScheme)
          .mask {
            RoundedRectangle(cornerRadius: PriceChartStyle.cardCornerRadius)
              .strokeBorder(lineWidth: 1.0 / displayScale)
          }
          .blendMode(PriceChartStyle.vibrantBlendMode(colorScheme))
          .allowsHitTesting(false)
      }
  }

  private var chartContent: some View {
    ZStack {
      if display.status == .loading {
        // Already the chart the prices will land in: the last three months along the bottom and an
        // axis estimated from the card's Scryfall price, so only the lines and the labels change.
        PriceHistoryChart(
          derivedData: display.chart,
          axis: display.axis,
          interaction: interaction,
          isLoading: true
        )
        .id(colorScheme)
        .transition(.opacity)
      } else {
        PriceHistoryChart(
          derivedData: display.chart,
          axis: display.axis,
          interaction: interaction
        )
        .id(colorScheme)
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
      // Tracking the global origin reports a change on every frame of a scroll or a pager
      // swipe, so it only exists while there is a dropdown to close.
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
