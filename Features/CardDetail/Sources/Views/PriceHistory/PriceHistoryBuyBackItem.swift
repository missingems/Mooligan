import Networking
import SwiftUI

/// The buy back ratio in a glass capsule. Tapping it morphs the capsule into the per-finish breakdown,
/// which grows over the chart without moving anything around it; tapping again, or scrubbing, folds
/// it back.
struct PriceHistoryBuyBackItem: View {
  let buyBack: BuyBackSummary
  let caption: String
  let interaction: ChartInteraction

  @State private var isExpanded: Bool
  @Namespace private var glass

  private static let glassID = "priceHistory.buyBack"
  private static let morph: Animation = .bouncy(duration: 0.35)

  init(buyBack: BuyBackSummary, caption: String, interaction: ChartInteraction, isExpanded: Bool = false) {
    self.buyBack = buyBack
    self.caption = caption
    self.interaction = interaction
    _isExpanded = State(initialValue: isExpanded)
  }

  private var isScrubbing: Bool { interaction.scrubbedDate != nil }

  var body: some View {
    VStack(alignment: .center, spacing: 3.0) {
      // The capsule's slot keeps the item's size; the glass inside it can grow past the slot.
      PriceHistoryToolbarValue(text: buyBack.ratioText, isAvailable: buyBack.isAvailable)
        .hidden()
        .overlay(alignment: .topTrailing) {
          GlassEffectContainer {
            if isExpanded {
              PriceHistoryBuyBackBreakdown(buyBack: buyBack)
                .contentShape(.rect(cornerRadius: 21.0))
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 21.0))
                .glassEffectID(Self.glassID, in: glass)
                .onTapGesture { setExpanded(false) }
            } else {
              PriceHistoryToolbarValue(text: buyBack.ratioText, isAvailable: buyBack.isAvailable)
                .glassEffect(buyBack.isAvailable ? .regular.interactive() : .regular)
                .glassEffectID(Self.glassID, in: glass)
                .onTapGesture { if buyBack.isAvailable { setExpanded(true) } }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(buyBack.isAvailable ? .isButton : [])
                .accessibilityAction { if buyBack.isAvailable { setExpanded(true) } }
                .accessibilityIdentifier("priceHistory.buyBack")
            }
          }
        }
        // Over its own caption; buy back is the last item in its row, so it is already over the rest.
        .zIndex(1.0)

      PriceHistoryToolbarCaption(text: caption, isAvailable: buyBack.isAvailable)
    }
    .frame(maxWidth: .infinity)
    // The ratio is today's; it does not follow the scrubbed day like the prices do.
    .opacity(isScrubbing ? 0.35 : 1.0)
    .animation(.snappy(duration: 0.24), value: isScrubbing)
    .onChange(of: isScrubbing) { _, scrubbing in
      if scrubbing { setExpanded(false) }
    }
    .onChange(of: buyBack.isAvailable) { _, available in
      if available == false { setExpanded(false) }
    }
  }

  private func setExpanded(_ expanded: Bool) {
    guard isExpanded != expanded else { return }
    withAnimation(Self.morph) { isExpanded = expanded }
  }
}
