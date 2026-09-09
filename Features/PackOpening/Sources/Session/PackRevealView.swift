import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

/// Cards coming out of a torn pack, dealt off the top of a stack.
///
/// The gesture is the whole interaction, so it is worth being fussy about. An
/// earlier version rode on a paged `ScrollView`, which bought real scroll
/// physics but never felt like *handling* a card: the pages were rails, the
/// snap was the scroll view's rather than the card's, and nothing about it
/// answered to how you took hold of it.
///
/// `CardStack` replaces that with a port of yuyakaido/CardStackView — the top
/// card follows the finger in both axes, pivots about the point opposite your
/// grip, and is thrown clear once it passes a threshold, with the rest of the
/// pack closing up behind it as it goes. What that model gives up is the
/// ability to scroll back, so the rewind CardStackView ships with earns its
/// place in the header.
struct PackRevealView: View {
  let revealOrder: [PulledCard]
  let revealedCount: Int

  /// How many cards have now been seen, after a card is dealt.
  let onRevealed: (Int) -> Void
  let onSkip: () -> Void

  /// The card currently in hand. `revealOrder.count` means the last one has
  /// been thrown and the pack is done.
  @State private var topIndex = 0

  /// How far the card in hand has been carried towards leaving, 0...1. Drives
  /// everything around the stack that ought to move with it.
  @State private var swipeProgress: CGFloat = 0

  @State private var rewindToken = 0
  @State private var dealToken = 0
  @State private var haptics = PackHaptics()

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var isFinished: Bool { topIndex >= revealOrder.count }

  private var focused: PulledCard? { revealOrder[safe: topIndex] }

  /// The card coming up, which the backdrop starts crossfading to as soon as
  /// the one on top is on its way out.
  private var upNext: PulledCard? { revealOrder[safe: topIndex + 1] }

  private var setting: CardStackSetting {
    var setting = CardStackSetting()
    // The tilt is the one part of the gesture that is decoration rather than
    // feedback, so it is the part that goes.
    if reduceMotion { setting.maxDegree = 0 }
    return setting
  }

  var body: some View {
    GeometryReader { proxy in
      let cardWidth = min(proxy.size.width * 0.68, 320)
      let cardSize = CGSize(
        width: cardWidth,
        height: cardWidth / MagicCardImageRatio.widthToHeight.rawValue
      )

      VStack(spacing: 20) {
        header

        ZStack {
          glow(cardWidth: cardWidth)
          finish(cardSize: cardSize)
          deck(cardSize: cardSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        pips
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
    }
    .onAppear {
      haptics.prepare()
      // The first card is already on top when the wrapper comes off, so it
      // counts as seen without the reader having to move anything.
      onRevealed(1)
    }
    .accessibilityIdentifier("packOpening.reveal")
  }

  // MARK: - Chrome

  private var header: some View {
    HStack(spacing: 12) {
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

      // Where you are in the pack rather than how much of it you have seen —
      // with a rewind to hand, the two come apart, and the pips already carry
      // the second reading.
      Text("\(min(topIndex + 1, revealOrder.count)) / \(revealOrder.count)")
        .font(.headline.monospacedDigit())
        .foregroundStyle(.white.opacity(0.85))
        .contentTransition(.numericText())
        .animation(.snappy, value: topIndex)
        .accessibilityIdentifier("packOpening.position")

      Spacer()

      Button("Reveal All", action: onSkip)
        .font(.subheadline.weight(.semibold))
        .buttonStyle(.borderless)
        .foregroundStyle(.white.opacity(0.7))
        .accessibilityIdentifier("packOpening.revealAll")
    }
    // Cleared of the session's close button, which is overlaid at the top
    // leading corner and was sitting on top of the count.
    .padding(.leading, 68)
    .padding(.trailing, 24)
    .padding(.top, 8)
  }

  /// One pip per card, filling in as the pack is worked through. Cheaper than a
  /// strip of thumbnails and still shows what came out: pips take the rarity
  /// colour.
  private var pips: some View {
    HStack(spacing: 5) {
      ForEach(Array(revealOrder.enumerated()), id: \.element.id) { index, card in
        Capsule()
          .fill(
            index < revealedCount
              ? AnyShapeStyle(card.rarity.revealGlow)
              : AnyShapeStyle(Color.white.opacity(0.16))
          )
          .frame(width: index < revealedCount ? 14 : 8, height: 4)
      }
    }
    .animation(.snappy, value: revealedCount)
    .padding(.bottom, 28)
    .accessibilityHidden(true)
  }

  // MARK: - The deck

  private func deck(cardSize: CGSize) -> some View {
    CardStack(
      count: revealOrder.count,
      cardSize: cardSize,
      setting: setting,
      topIndex: $topIndex,
      swipeProgress: $swipeProgress,
      rewindToken: rewindToken,
      dealToken: dealToken,
      onThresholdCrossed: { haptics.swipeThresholdCrossed() }
    ) { index in
      RevealedCardView(
        pulled: revealOrder[index],
        width: cardSize.width,
        // Only the card in hand captions itself; on the ones behind it the
        // caption shows through the gap as stray text.
        showsCaption: index == topIndex
      )
    }
    .onChange(of: topIndex) { previous, index in
      guard index > previous else { return }

      if index >= revealOrder.count {
        onSkip()
      } else {
        haptics.reveal(isHit: revealOrder[safe: index]?.isHit ?? false)
        onRevealed(index + 1)
      }
    }
    // The stack is one gesture rather than a scroll view, so VoiceOver needs
    // the same two moves spelled out for it.
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Card \(min(topIndex + 1, revealOrder.count)) of \(revealOrder.count)")
    .accessibilityHint("Swipe for the next card")
    .accessibilityIdentifier("packOpening.deck")
    .accessibilityAction(named: "Next card") { dealNext() }
    .accessibilityAction(named: "Previous card") { rewindToken += 1 }
    .accessibilityScrollAction { edge in
      switch edge {
      case .leading, .top: rewindToken += 1
      default: dealNext()
      }
    }
  }

  /// Throws the card in hand without a drag, for VoiceOver and for anyone
  /// driving the app from the keyboard.
  private func dealNext() {
    dealToken += 1
  }

  /// Sits behind the stack and shows through as the last card is pulled away,
  /// so the pack empties into something rather than into nothing.
  private func finish(cardSize: CGSize) -> some View {
    VStack(spacing: 10) {
      Image(systemName: "square.grid.2x2")
        .font(.largeTitle)
        .foregroundStyle(.white.opacity(0.5))

      Text("That's the pack")
        .font(.headline)
        .foregroundStyle(.white.opacity(0.85))

      Text("See everything you pulled")
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.55))
    }
    .frame(width: cardSize.width, height: cardSize.height)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cardSize.width * 0.05, style: .continuous))
    .opacity(finishOpacity)
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isButton)
    .accessibilityAction { onSkip() }
    .accessibilityHidden(finishOpacity == 0)
  }

  private var finishOpacity: Double {
    if isFinished { return 1 }
    // Only uncovered by the last card in the pack going.
    guard topIndex == revealOrder.count - 1 else { return 0 }
    return Double(swipeProgress)
  }

  /// Rarity halo behind the card. Rares and mythics also get rays, which is the
  /// moment the whole screen exists for.
  ///
  /// Crossfaded by how far the top card has been dragged rather than switched
  /// when it lands, which is CardStackView's overlay trick turned around: the
  /// backdrop starts becoming the next card's the moment you start pulling this
  /// one away.
  @ViewBuilder
  private func glow(cardWidth: CGFloat) -> some View {
    ZStack {
      if let focused {
        halo(for: focused, cardWidth: cardWidth)
          .opacity(1 - Double(swipeProgress))
      }

      if let upNext {
        halo(for: upNext, cardWidth: cardWidth)
          .opacity(Double(swipeProgress))
      }
    }
    .allowsHitTesting(false)
  }

  private func halo(for pulled: PulledCard, cardWidth: CGFloat) -> some View {
    ZStack {
      RadialGradient(
        colors: [pulled.rarity.revealGlow.opacity(pulled.isHit ? 0.75 : 0.3), .clear],
        center: .center,
        startRadius: 0,
        endRadius: cardWidth
      )
      .blur(radius: 24)

      if pulled.isHit {
        RayBurst(rayCount: 18)
          .fill(pulled.rarity.revealGlow.opacity(0.28))
          .blendMode(.plusLighter)
          .frame(width: cardWidth * 2.4, height: cardWidth * 2.4)
          .rotationEffect(.degrees(reduceMotion ? 0 : 8))
          .blur(radius: 4)
      }
    }
  }
}

// MARK: - Card faces

struct RevealedCardView: View {
  let pulled: PulledCard
  let width: CGFloat

  /// Only the card on top of the stack captions itself — on the ones behind it
  /// the caption shows through the gap as stray text.
  var showsCaption = true

  @State private var isImageLoaded = false

  var body: some View {
    Group {
      if let url = pulled.card.getImageURL(types: [.normal, .large, .small]) {
        CardRemoteImageView(
          url: url,
          isLandscape: pulled.card.isLandscape,
          size: CGSize(width: width, height: width / MagicCardImageRatio.widthToHeight.rawValue),
          id: pulled.id.uuidString,
          isImageLoaded: $isImageLoaded
        )
      } else {
        RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
          .fill(Color(white: 0.15))
          .frame(width: width, height: width / MagicCardImageRatio.widthToHeight.rawValue)
          .overlay {
            Text(pulled.card.name)
              .font(.headline)
              .foregroundStyle(.white)
              .padding()
              .multilineTextAlignment(.center)
          }
      }
    }
    .overlay(alignment: .bottom) {
      if showsCaption {
        caption
          .offset(y: 30)
      }
    }
    .shadow(color: pulled.rarity.revealGlow.opacity(pulled.isHit ? 0.55 : 0), radius: 22)
    .shadow(color: .black.opacity(0.5), radius: 18, y: 12)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(pulled.card.name), \(pulled.rarity.displayName)\(pulled.isFoil ? ", foil" : "")"
    )
  }

  private var caption: some View {
    HStack(spacing: 6) {
      if pulled.isFoil {
        Image(systemName: "sparkles").imageScale(.small)
      }

      Text(pulled.rarity.displayName)
        .font(.caption.weight(.semibold))

      if let price = pulled.price, price > 0 {
        Text(price, format: .currency(code: "USD"))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.white.opacity(0.7))
      }
    }
    .foregroundStyle(pulled.rarity.revealGlow)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(.ultraThinMaterial, in: Capsule())
  }
}

// MARK: - Effects

/// Radiating spokes behind a hit.
struct RayBurst: Shape {
  let rayCount: Int

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2
    let halfWidth = .pi / Double(rayCount) * 0.35

    for ray in 0..<rayCount {
      let angle = Double(ray) / Double(rayCount) * 2 * .pi

      path.move(to: center)
      path.addLine(
        to: CGPoint(
          x: center.x + cos(angle - halfWidth) * radius,
          y: center.y + sin(angle - halfWidth) * radius
        )
      )
      path.addLine(
        to: CGPoint(
          x: center.x + cos(angle + halfWidth) * radius,
          y: center.y + sin(angle + halfWidth) * radius
        )
      )
      path.closeSubpath()
    }

    return path
  }
}
