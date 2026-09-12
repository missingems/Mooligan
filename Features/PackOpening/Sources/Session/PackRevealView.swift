import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

/// The whole of an opened pack, from the first card to the finished grid.
///
/// One screen, not two. Cards are dealt off a stack into a row of slots along
/// the bottom, and when the pack runs out that same row opens into the grid —
/// the summary is this view in another state rather than somewhere else you get
/// sent, so every card stays the card it was instead of being replaced by a
/// picture of itself on a new screen.
///
/// The gesture is a port of yuyakaido/CardStackView: the top card follows the
/// finger in both axes, pivots about the point opposite your grip, and is
/// thrown once it passes a threshold, with the rest of the pack closing up
/// behind it. Rather than being thrown off-screen it is thrown *at* its own
/// slot, which is what makes dealing a card and filing it the same movement.
struct PackRevealView: View {
  let pack: BoosterPack
  let revealedCount: Int
  let isSummary: Bool

  /// How many cards have now been seen, after a card is dealt.
  let onRevealed: (Int) -> Void
  /// A card was tapped rather than thrown: open it in full.
  let onSelect: (PulledCard) -> Void
  let onRevealAll: () -> Void
  let onOpenAnother: () -> Void
  let onDone: () -> Void

  /// Everything ripped in this sitting so far.
  let history: PackSessionFeature.State.History

  /// The card currently in hand.
  @State private var topIndex = 0

  /// How far the card in hand has been carried towards leaving, 0...1.
  @State private var swipeProgress: CGFloat = 0

  @State private var rewindToken = 0
  @State private var dealToken = 0
  @State private var haptics = PackHaptics()

  /// Frames of the stack and of the row of slots, so a thrown card knows where
  /// it is going.
  @State private var deckFrame: CGRect = .zero
  @State private var stripFrame: CGRect = .zero

  /// How much of the screen the next pack covers where it peeks up from the
  /// bottom edge, so the grid can be scrolled clear of it. Measured rather than
  /// guessed: it is a pack drawn at its own aspect ratio, not a fixed bar.
  @State private var nextPackHeight: CGFloat = 0

  /// The space the reveal has to work in. Seeded so the first pass lays out
  /// something sensible; corrected on the first real measurement.
  @State private var viewSize = CGSize(width: 393, height: 780)

  /// Ties a card's slot in the row to its cell in the grid. Both live in this
  /// view, so the row can grow into the grid.
  @Namespace private var cardMorph

  /// Whether the row-into-grid morph is still running.
  ///
  /// `matchedGeometryEffect` is not free once the movement is over. Every
  /// participant publishes its frame into the namespace on each layout pass and
  /// SwiftUI reconciles the pairs, so fifteen matched cards inside a scrolling
  /// `LazyVGrid` go on paying for a transition that finished seconds ago —
  /// which is why the grid scrolled cleanly before the morph existed and
  /// stuttered afterwards. The effect is retired once the cards have arrived.
  @State private var isMorphing = false

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  // `nonisolated` because the geometry closures that name it are `@Sendable`,
  // and a `static let` on a main-actor view is main-actor isolated by default.
  private nonisolated static let space = "packReveal"

  private var revealOrder: [PulledCard] { pack.revealOrder }

  private var focused: PulledCard? { revealOrder[safe: topIndex] }

  /// The cards already dealt away, newest last.
  ///
  /// Deliberately excludes the card in hand. A card is in exactly one place at
  /// a time: while it is on the stack it belongs to the stack, and it joins the
  /// row at the moment it is thrown — which is what makes the throw read as the
  /// card *becoming* its slot rather than being copied into it.
  private var revealed: [PulledCard] {
    isSummary ? revealOrder : Array(revealOrder.prefix(min(topIndex, revealOrder.count)))
  }

  /// What the pack has been worth so far — everything dealt, plus the card
  /// being looked at, which has been seen even if it has not been put down.
  private var runningTotal: Decimal {
    guard isSummary == false else { return pack.totalValue }

    return revealOrder
      .prefix(min(topIndex + 1, revealOrder.count))
      .reduce(Decimal.zero) { $0 + ($1.price ?? 0) }
  }

  /// What the sitting has come to: packs opened, cards pulled, and what the
  /// lot is worth.
  private var sessionTally: String {
    let packs = history.packs == 1 ? "1 pack" : "\(history.packs) packs"
    let sets = history.setCodes.count > 1 ? " · \(history.setCodes.count) sets" : ""

    return "\(packs)\(sets) · \(history.cards) cards · \(history.value.formatted(.currency(code: "USD")))"
  }

  private var setting: CardStackSetting {
    var setting = CardStackSetting()
    // The tilt is the one part of the gesture that is decoration rather than
    // feedback, so it is the part that goes.
    if reduceMotion { setting.maxDegree = 0 }
    return setting
  }

  var body: some View {
    Group {
      if isSummary {
        summaryLayout
      } else {
        dealingLayout
      }
    }
    .onChange(of: isSummary) { _, summary in
      guard summary else {
        isMorphing = false
        return
      }

      isMorphing = true
      Task {
        // A shade longer than the 0.45s phase animation, then dropped without
        // an animation of its own. Every card is already at its final frame by
        // then, so removing the effect moves nothing.
        try? await Task.sleep(for: .milliseconds(650))
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { isMorphing = false }
      }
    }
    .onAppear {
      haptics.prepare()
      // The first card is already on top when the wrapper comes off, so it
      // counts as seen without the reader having to move anything.
      onRevealed(1)
    }
    .accessibilityIdentifier(isSummary ? "packOpening.summary" : "packOpening.reveal")
  }

  /// The finished pack.
  ///
  /// Deliberately not inside a `GeometryReader`. Dealing needs one — a thrown
  /// card is aimed using measured frames — but the grid inherited it when the
  /// two screens were merged, and a scroll view under a geometry reader that is
  /// itself inside a fixed frame re-proposes its layout as the content moves.
  /// That is what started the scrolling stutter that was not there when the
  /// summary was its own screen. The grid sizes itself from the columns
  /// instead, and measures nothing.
  private var summaryLayout: some View {
    VStack(spacing: 14) {
      header
      grid
    }
    // The next pack waits at the bottom edge, showing just enough of itself to
    // be grabbed. Opening another is the thing people do most from here, and a
    // pack you pull out is a better invitation than a button that says so.
    .overlay(alignment: .bottom) {
      NextPackView(
        product: pack.product,
        visibleHeight: $nextPackHeight,
        onOpenAnother: onOpenAnother
      )
    }
  }

  /// Measured with `onGeometryChange` rather than wrapped in a `GeometryReader`.
  ///
  /// A `GeometryReader` is not a measurement: it is a layout container that
  /// takes all the space offered and hands its children a proposal of its own,
  /// so everything under it re-proposes whenever it resizes. Dealing only needs
  /// to *know* the width — to size a card and to aim a throw at a slot — and
  /// `onGeometryChange` reports that without standing between the stack and its
  /// parent.
  private var dealingLayout: some View {
    let cardWidth = min(viewSize.width * 0.68, 300)
    let cardSize = CGSize(
      width: cardWidth,
      height: cardWidth / MagicCardImageRatio.widthToHeight.rawValue
    )

    return VStack(spacing: 14) {
      header

      deck(cardSize: cardSize, viewWidth: viewSize.width)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: {
          deckFrame = $0
        }

      currentPrice
      slots(viewWidth: viewSize.width)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .coordinateSpace(.named(Self.space))
    .onGeometryChange(for: CGSize.self) { $0.size } action: { viewSize = $0 }
  }

  // MARK: - Chrome

  @ViewBuilder
  private var header: some View {
    HStack(spacing: 10) {
      if isSummary == false {
        Button {
          rewindToken += 1
        } label: {
          Image(systemName: "arrow.uturn.backward")
            .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.white.opacity(0.7))
        .disabled(topIndex == 0)
        .opacity(topIndex == 0 ? 0 : 1)
        .animation(.snappy, value: topIndex == 0)
        .accessibilityLabel("Previous card")
        .accessibilityIdentifier("packOpening.rewind")
      }

      VStack(alignment: .leading, spacing: 1) {
        Text(
          isSummary
            ? pack.product.set.name
            : "\(min(topIndex + 1, revealOrder.count)) / \(revealOrder.count)"
        )
        .font(.subheadline.weight(.semibold).monospacedDigit())
        .foregroundStyle(.white.opacity(0.7))
        .lineLimit(1)

        Text(runningTotal, format: .currency(code: "USD"))
          .font(.headline.monospacedDigit())
          .foregroundStyle(.white)
          .contentTransition(.numericText())

        if isSummary, history.isWorthShowing {
          Text(sessionTally)
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.white.opacity(0.45))
            .lineLimit(1)
        }
      }
      .animation(.snappy, value: revealed.count)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("packOpening.position")

      Spacer()

      if isSummary == false {
        Button("Reveal All", action: onRevealAll)
          .font(.subheadline.weight(.semibold))
          .buttonStyle(.borderless)
          .foregroundStyle(.white.opacity(0.7))
          .accessibilityIdentifier("packOpening.revealAll")
      }
    }
    // Cleared of the session's close button, which is overlaid at the top
    // leading corner.
    .padding(.leading, 64)
    .padding(.trailing, 24)
    .padding(.top, 8)
  }

  /// The one price on screen while dealing: what the card in hand is worth.
  @ViewBuilder
  private var currentPrice: some View {
    if let focused {
      HStack(spacing: 6) {
        if focused.isFoil {
          Image(systemName: "sparkles").imageScale(.small)
        }

        Text(focused.rarity.displayName)
          .font(.caption.weight(.semibold))

        if let price = focused.price, price > 0 {
          Text(verbatim: "·")
            .foregroundStyle(.white.opacity(0.3))

          Text(price, format: .currency(code: "USD"))
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .foregroundStyle(.white)
            .contentTransition(.numericText())
        }

        // How rare the pull actually was, which is the other half of what makes
        // a card worth looking at: a cheap card out of a one-in-two-hundred
        // slot is still a story.
        if let odds = focused.oddsDescription {
          Text(verbatim: "·")
            .foregroundStyle(.white.opacity(0.3))

          Text(odds)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.55))
        }
      }
      .foregroundStyle(.white.opacity(0.75))
      .padding(.horizontal, 14)
      .padding(.vertical, 7)
      .background(Color.white.opacity(0.1), in: Capsule())
      .animation(.snappy, value: focused.id)
      .accessibilityIdentifier("packOpening.currentPrice")
    }
  }

  // MARK: - The row of slots

  /// Metrics for the row along the bottom.
  ///
  /// The row does not scroll: every card has a slot from the outset, which is
  /// what lets a thrown card be aimed at its *own* slot. A scrolling row's
  /// slots move, and one near either end cannot be brought to a predictable
  /// place at all.
  ///
  /// Fourteen cards laid side by side across a phone leaves each about twenty
  /// points wide, which is a row of stamps rather than a row of cards. They
  /// overlap instead, like a hand being held — `pitch` is the step from one to
  /// the next, and it being smaller than `size` is the whole point.
  private func slotMetrics(width: CGFloat) -> (size: CGFloat, pitch: CGFloat, inset: CGFloat) {
    let inset: CGFloat = 16
    let count = CGFloat(max(revealOrder.count, 1))
    let span = width - inset * 2

    let size = min(max(span / count * 1.9, 24), 52)
    let pitch = count > 1 ? min((span - size) / (count - 1), size + 6) : 0

    return (size, pitch, inset)
  }

  private func slots(viewWidth: CGFloat) -> some View {
    let slot = slotMetrics(width: viewWidth)

    return HStack(spacing: slot.pitch - slot.size) {
      ForEach(Array(revealOrder.enumerated()), id: \.element.id) { index, card in
        Group {
          if index < revealed.count {
            PulledCardImage(pulled: card, width: slot.size)
              .modifier(
                CardMorph(id: card.id, namespace: cardMorph, isActive: isMorphing)
              )
              .onTapGesture { onSelect(card) }
              .accessibilityAddTraits(.isButton)
              .accessibilityLabel(card.card.name)
          } else {
            RoundedRectangle(cornerRadius: slot.size * 0.06, style: .continuous)
              .fill(Color.white.opacity(0.08))
              .frame(
                width: slot.size,
                height: slot.size / MagicCardImageRatio.widthToHeight.rawValue
              )
              .accessibilityHidden(true)
          }
        }
        // Later cards lie over earlier ones, so the one just put down is the
        // one fully in view.
        .zIndex(Double(index))
        .accessibilityIdentifier("packOpening.strip.\(card.id.uuidString)")
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, slot.inset)
    .padding(.bottom, 20)
    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: {
      stripFrame = $0
    }
  }

  // MARK: - The grid

  /// The row of slots, opened out. Same cards, same view, more room.
  ///
  /// A view of its own, and deliberately so. Measured with `_printChanges`, a
  /// single `@State` change on `PackRevealView` — and it has a dozen of them,
  /// several written while a finger is down — re-evaluated this whole body,
  /// which meant rebuilding all fifteen grid cells. Each cell is a decoded card
  /// image behind a `clipShape` and a stroked overlay, so that is fifteen
  /// offscreen passes thrown away and redone for a change that had nothing to
  /// do with the grid. Taking only what it needs means nothing else can reach
  /// it.
  ///
  /// Shown in reveal order, which is the order the row along the bottom is in,
  /// so opening the row out moves every card the shortest distance to where it
  /// already was — and the pack still finishes on the card it built up to.
  private var grid: some View {
    PackGrid(
      cards: revealOrder,
      cardMorph: cardMorph,
      isMorphing: isMorphing,
      bottomInset: nextPackHeight,
      onSelect: onSelect,
      actions: { actions }
    )
  }

  private var actions: some View {
    VStack(spacing: 10) {
      Button(action: onOpenAnother) {
        Label("Open Another", systemImage: "arrow.clockwise")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .accessibilityIdentifier("packOpening.openAnother")

      Button("Done", action: onDone)
        .buttonStyle(.bordered)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .foregroundStyle(.white)
        .accessibilityIdentifier("packOpening.done")
    }
    // Left to the grid's own margins: the buttons line up with the cards
    // above them, and the room to scroll clear of the next pack is the scroll
    // view's bottom inset rather than padding this block carries around.
    .padding(.top, 20)
  }

  // MARK: - The deck

  /// Where a thrown card goes: the slot it is about to occupy, at slot size.
  private func landing(cardWidth: CGFloat, viewWidth: CGFloat) -> CardStackLanding? {
    guard deckFrame != .zero, stripFrame != .zero, cardWidth > 0 else { return nil }
    guard topIndex < revealOrder.count else { return nil }

    let slot = slotMetrics(width: viewWidth)
    let centreX =
      stripFrame.minX + slot.inset
      + CGFloat(topIndex) * slot.pitch
      + slot.size / 2

    return CardStackLanding(
      offset: CGSize(
        width: centreX - deckFrame.midX,
        height: stripFrame.midY - deckFrame.midY
      ),
      scale: slot.size / cardWidth
    )
  }

  private func deck(cardSize: CGSize, viewWidth: CGFloat) -> some View {
    CardStack(
      count: revealOrder.count,
      cardSize: cardSize,
      setting: setting,
      landing: landing(cardWidth: cardSize.width, viewWidth: viewWidth),
      topIndex: $topIndex,
      swipeProgress: $swipeProgress,
      rewindToken: rewindToken,
      dealToken: dealToken,
      onThresholdCrossed: { haptics.swipeThresholdCrossed() }
    ) { index in
      PulledCardImage(pulled: revealOrder[index], width: cardSize.width, isFoilAnimated: true)
        .shadow(color: .black.opacity(0.5), radius: 18, y: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          "\(revealOrder[index].card.name), \(revealOrder[index].rarity.displayName)"
        )
    }
    .onChange(of: topIndex) { previous, index in
      guard index > previous else { return }

      if index >= revealOrder.count {
        onRevealAll()
      } else {
        haptics.reveal(isHit: revealOrder[safe: index]?.isHit ?? false)
        onRevealed(index + 1)
      }
    }
    // A tap is a short drag that never passed the threshold, so the two
    // gestures do not fight: the stack's own `DragGesture` needs a pixel of
    // travel before it takes over.
    .onTapGesture {
      if let focused { onSelect(focused) }
    }
    .accessibilityIdentifier("packOpening.deck")
    .accessibilityAction(named: "Show card details") {
      if let focused { onSelect(focused) }
    }
    .accessibilityAction(named: "Next card") { dealToken += 1 }
    .accessibilityAction(named: "Previous card") { rewindToken += 1 }
    .accessibilityScrollAction { edge in
      switch edge {
      case .leading, .top: rewindToken += 1
      default: dealToken += 1
      }
    }
  }
}

// MARK: - Card faces

/// A pulled card's artwork, at whatever size it is being shown.
///
/// One view and, crucially, one image request whatever the size: the slot along
/// the bottom and the card in hand ask for the same URL, and so does the
/// `CardView` in the finished grid — the one the pack prefetched before it
/// opened. Asking for the small printing in the row and the normal one on the
/// stack meant the row's copy was a separate, uncached download that faded in
/// on arrival: the card blinked at the end of every throw, and the pack quietly
/// fetched a second image of every card it had already downloaded.
struct PulledCardImage: View {
  let pulled: PulledCard

  /// A fixed width, or `nil` to fill whatever space is offered.
  var width: CGFloat?

  /// Whether the foil sheen runs on a clock.
  ///
  /// Only the card being looked at earns that. The shader sits inside a
  /// `TimelineView` driving a redraw thirty times a second, and a row of
  /// fifteen foil slots is fifteen of them ticking at once. Everywhere else the
  /// sheen is drawn once and left.
  var isFoilAnimated = false

  @State private var isImageLoaded = false

  private static var ratio: CGFloat { MagicCardImageRatio.widthToHeight.rawValue }

  @ViewBuilder
  var body: some View {
    if let width {
      face.frame(width: width, height: width / Self.ratio)
    } else {
      face.aspectRatio(Self.ratio, contentMode: .fit)
    }
  }

  /// The shader is attached only to cards that are actually foil. Applying it
  /// at zero intensity to the rest still costs a full offscreen pass and a
  /// `TimelineView` each, which is most of what made a screen of cards stutter.
  @ViewBuilder
  private var face: some View {
    if pulled.isFoil {
      artwork.holographicFoil(intensity: 0.42, isAnimated: isFoilAnimated)
    } else {
      artwork
    }
  }

  @ViewBuilder
  private var artwork: some View {
    if let url = pulled.imageURL {
      CardRemoteImageView(
        url: url,
        isLandscape: pulled.card.isLandscape,
        size: width.map { CGSize(width: $0, height: $0 / Self.ratio) },
        id: pulled.id.uuidString,
        isImageLoaded: $isImageLoaded
      )
    } else {
      RoundedRectangle(cornerRadius: (width ?? 40) * 0.05, style: .continuous)
        .fill(Color(white: 0.15))
        .overlay {
          Text(pulled.card.name)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(4)
            .multilineTextAlignment(.center)
        }
    }
  }
}


/// Carries a card between its slot in the row and its cell in the grid, and
/// only while that is actually happening.
///
/// Applied as a modifier rather than inline so the branch is confined to this
/// one wrapper: the card image underneath keeps its identity either way, and so
/// is never torn down and rebuilt when the effect is retired.
private struct CardMorph: ViewModifier {
  let id: UUID
  let namespace: Namespace.ID
  let isActive: Bool

  func body(content: Content) -> some View {
    if isActive {
      content.matchedGeometryEffect(id: id, in: namespace)
    } else {
      content
    }
  }
}


/// The finished pack, laid out the way this app lays out any grid of cards.
///
/// Deliberately the set grid's arrangement rather than one of its own: a plain
/// `LazyVGrid` of `CardView`s sized from the measured width, with no rarity
/// sections, no headers, and no price or odds under each card. Those numbers
/// belong to the reveal, where they are read one at a time against the card
/// they describe; repeated fifteen times under a grid they are a wall of small
/// type over the only thing worth looking at. Reusing `CardView` also means the
/// grid scrolled here is the grid scrolled in a set — including turning a
/// double-faced card over — rather than a second implementation that has to be
/// made smooth separately.
///
/// Split out of `PackRevealView` so that view's state cannot invalidate it.
/// Everything it needs is passed in, and none of it changes while the grid is
/// being scrolled.
private struct PackGrid<Actions: View>: View {
  let cards: [PulledCard]
  let cardMorph: Namespace.ID
  let isMorphing: Bool

  /// Room at the foot of the scroll for the pack peeking up over it, so the
  /// last row and the buttons can be brought out from behind it.
  let bottomInset: CGFloat

  let onSelect: (PulledCard) -> Void
  @ViewBuilder let actions: () -> Actions

  /// Resolved from the measured width, exactly as the set grid does it, so each
  /// cell is laid out at a size that is already known rather than working one
  /// out from the image that turns up in it.
  @State private var layout: CardView.LayoutConfiguration?

  private static var columnCount: CGFloat { 2 }
  private static var spacing: CGFloat { 8 }

  private var columns: [GridItem] {
    [GridItem](
      repeating: GridItem(spacing: Self.spacing, alignment: .center),
      count: Int(Self.columnCount)
    )
  }

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: Self.spacing) {
        if let layout {
          ForEach(cards) { pulled in
            PackGridCell(
              pulled: pulled,
              layout: layout,
              cardMorph: cardMorph,
              isMorphing: isMorphing,
              onSelect: onSelect
            )
          }
        }
      }

      actions()
    }
    .scrollBounceBehavior(.basedOnSize)
    .contentMargins(
      .all,
      EdgeInsets(
        top: 0,
        leading: systemHorizontalMargin,
        bottom: bottomInset,
        trailing: systemHorizontalMargin
      ),
      for: .scrollContent
    )
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
      let gutters = Self.spacing * (Self.columnCount - 1)
      let columnWidth =
        ((width - systemHorizontalMargin * 2 - gutters) / Self.columnCount).rounded(.down)

      guard columnWidth > 0, layout?.size.width != columnWidth else { return }
      layout = CardView.LayoutConfiguration(rotation: .portrait, maxWidth: columnWidth)
    }
  }
}


/// One card in the finished pack.
private struct PackGridCell: View {
  let pulled: PulledCard
  let layout: CardView.LayoutConfiguration
  let cardMorph: Namespace.ID
  let isMorphing: Bool
  let onSelect: (PulledCard) -> Void

  /// Which way up a double-faced card is being shown.
  ///
  /// Held by the cell rather than for the grid as a whole: turning one card
  /// over should redraw that card and not the fourteen around it.
  @State private var face: DisplayableCardImage?

  private var displayable: DisplayableCardImage? { face ?? pulled.displayableCardImage }

  var body: some View {
    CardView(
      displayableCard: displayable,
      layoutConfiguration: layout,
      callToActionHorizontalOffset: -3.0,
      priceVisibility: .hidden,
      // A card pulled as a foil looks foil, but the sheen is drawn once and
      // left: a whole collector booster of animated foils is fifteen shaders
      // redrawing thirty times a second behind the scroll.
      isFoilOnly: pulled.isFoil,
      isFoilAnimated: false,
      send: { _ in face = displayable?.toggled() }
    )
    .modifier(CardMorph(id: pulled.id, namespace: cardMorph, isActive: isMorphing))
    .contentShape(.rect)
    .onTapGesture { onSelect(pulled) }
    .accessibilityElement(children: .ignore)
    .accessibilityAddTraits(.isButton)
    .accessibilityLabel(
      "\(pulled.card.name), \(pulled.rarity.displayName)\(pulled.isFoil ? ", foil" : "")"
    )
    .accessibilityIdentifier("packOpening.summaryCard.\(pulled.id.uuidString)")
  }
}


/// The next pack, waiting at the bottom edge to be pulled out.
///
/// Owns the drag rather than reporting it upwards. While the travel lived on
/// `PackRevealView` every frame of the pull re-evaluated that view's body, and
/// with it the grid of fifteen cards sitting behind this one — a redraw of the
/// whole screen for a gesture that moves one wrapper.
private struct NextPackView: View {
  let product: PackProduct

  /// How much of itself it covers the screen with while parked, reported back
  /// so the grid behind it knows how far it has to be able to scroll.
  @Binding var visibleHeight: CGFloat

  let onOpenAnother: () -> Void

  /// How far the pack has been pulled up out of the bottom of the screen.
  @State private var pull: CGFloat = 0

  /// How much of the pack shows before anything is dragged, and how far it has
  /// to come to count as opened.
  private let peek: CGFloat = 96
  private let travel: CGFloat = 130

  var body: some View {
    VStack(spacing: 8) {
      Capsule()
        .fill(.white.opacity(0.35))
        .frame(width: 36, height: 4)

      Text("Pull up for another")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.6))

      BoosterPackView(product: product)
        .frame(maxWidth: 150)
    }
    .padding(.top, 10)
    .frame(maxWidth: .infinity)
    .background(
      LinearGradient(
        colors: [.clear, Color(white: 0.06).opacity(0.9), Color(white: 0.06)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    )
    // Parked below the fold with only its head showing, and pulled up as the
    // finger moves.
    .offset(y: peek - pull)
    .gesture(
      DragGesture(minimumDistance: 4)
        .onChanged { value in
          pull = min(max(-value.translation.height, 0), travel)
        }
        .onEnded { value in
          let pulled = min(max(-value.predictedEndTranslation.height, 0), travel * 2)

          if pulled >= travel * 0.6 {
            // Carry it the rest of the way, then hand over: the new pack
            // arrives sealed in the same place this one was pulled from.
            withAnimation(.easeOut(duration: 0.22)) { pull = travel }
            onOpenAnother()
          } else {
            withAnimation(.spring(duration: 0.4, bounce: 0.3)) { pull = 0 }
          }
        }
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Open another pack")
    .accessibilityAddTraits(.isButton)
    .accessibilityAction { onOpenAnother() }
    .accessibilityIdentifier("packOpening.nextPack")
    // Measured whole and trimmed here rather than in the geometry closure,
    // which is `@Sendable` and so cannot reach `peek` on a main-actor view.
    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
      visibleHeight = max(height - peek, 0)
    }
  }
}
