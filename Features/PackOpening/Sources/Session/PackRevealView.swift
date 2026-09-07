import DesignComponents
import Networking
import ScryfallKit
import SwiftUI

/// Cards coming out of a torn pack, one tap at a time.
struct PackRevealView: View {
  let pack: BoosterPack
  let revealOrder: [PulledCard]
  let revealedCount: Int
  let onReveal: () -> Void
  let onSkip: () -> Void

  @State private var haptics = PackHaptics()
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var displayed: PulledCard? {
    revealedCount > 0 ? revealOrder[safe: revealedCount - 1] : nil
  }

  private var remaining: Int {
    max(0, revealOrder.count - revealedCount)
  }

  var body: some View {
    GeometryReader { proxy in
      let cardWidth = min(proxy.size.width * 0.68, 320)

      VStack(spacing: 20) {
        header

        ZStack {
          if let displayed {
            glow(for: displayed, cardWidth: cardWidth)
          }

          faceDownDeck(cardWidth: cardWidth)

          if let displayed {
            RevealedCardView(pulled: displayed, width: cardWidth)
              .id(displayed.id)
              .transition(
                .asymmetric(
                  insertion: .modifier(
                    active: FlipModifier(angle: -92, scale: 0.86),
                    identity: FlipModifier(angle: 0, scale: 1)
                  ),
                  removal: .modifier(
                    active: FlipModifier(angle: 12, scale: 0.7, opacity: 0),
                    identity: FlipModifier(angle: 0, scale: 1)
                  )
                )
              )
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(
          reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.5, bounce: 0.28),
          value: revealedCount
        )

        pips
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .contentShape(Rectangle())
      .onTapGesture {
        guard remaining > 0 else { return }
        haptics.reveal(isHit: revealOrder[safe: revealedCount]?.isHit ?? false)
        onReveal()
      }
    }
    .onAppear { haptics.prepare() }
    .accessibilityIdentifier("packOpening.reveal")
  }

  // MARK: - Chrome

  private var header: some View {
    HStack {
      Text("\(min(revealedCount, revealOrder.count)) / \(revealOrder.count)")
        .font(.headline.monospacedDigit())
        .foregroundStyle(.white.opacity(0.85))

      Spacer()

      Button("Reveal All", action: onSkip)
        .font(.subheadline.weight(.semibold))
        .buttonStyle(.borderless)
        .foregroundStyle(.white.opacity(0.7))
        .accessibilityIdentifier("packOpening.revealAll")
    }
    .padding(.horizontal, 24)
    .padding(.top, 8)
  }

  /// One pip per card, filling in as the pack is revealed. Cheaper than a strip
  /// of thumbnails and still shows what came out: pips take the rarity colour.
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

  // MARK: - Cards

  private func faceDownDeck(cardWidth: CGFloat) -> some View {
    ZStack {
      ForEach(0..<min(4, remaining), id: \.self) { index in
        CardBackView(product: pack.product, width: cardWidth)
          .scaleEffect(1 - CGFloat(index) * 0.02)
          .offset(y: CGFloat(index) * 7)
          .zIndex(-Double(index))
      }
    }
    .offset(y: remaining > 0 ? 26 : 0)
    .opacity(remaining > 0 ? 1 : 0)
    .animation(.snappy, value: remaining)
  }

  /// Rarity halo behind the card. Rares and mythics also get rays, which is the
  /// moment the whole screen exists for.
  private func glow(for pulled: PulledCard, cardWidth: CGFloat) -> some View {
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
    .transition(.opacity)
    .allowsHitTesting(false)
  }
}

// MARK: - Card faces

struct RevealedCardView: View {
  let pulled: PulledCard
  let width: CGFloat

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
    .modifier(FoilFinish(isFoil: pulled.isFoil))
    .overlay(alignment: .bottom) {
      caption
        .offset(y: 30)
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

/// The back of a card still in the pack. Deliberately generic art — it stands in
/// for a face-down card rather than reproducing the real Magic card back.
struct CardBackView: View {
  let product: PackProduct
  let width: CGFloat

  var body: some View {
    let theme = PackTheme(setCode: product.set.code, kind: product.kind)
    let height = width / MagicCardImageRatio.widthToHeight.rawValue

    RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
      .fill(
        LinearGradient(
          colors: [theme.shadow, theme.base.opacity(0.85), theme.shadow],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay {
        RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
          .inset(by: width * 0.045)
          .strokeBorder(theme.accent.opacity(0.55), lineWidth: 1.5)
      }
      .overlay {
        IconLazyImage(product.iconURL, tintColor: theme.accent.opacity(0.5))
          .frame(width: width * 0.42, height: width * 0.42)
      }
      .frame(width: width, height: height)
      .shadow(color: .black.opacity(0.4), radius: 10, y: 6)
  }
}

// MARK: - Effects

/// Applies the foil shader only to the pulls that earned it, so a pack of
/// commons costs nothing to render.
struct FoilFinish: ViewModifier {
  let isFoil: Bool

  func body(content: Content) -> some View {
    if isFoil {
      content.holographicFoil(intensity: 0.34)
    } else {
      content
    }
  }
}

/// Half of a card flip, as a transition modifier.
///
/// Deliberately not `Animatable`: the effects it applies are each animatable in
/// their own right, so SwiftUI interpolates between the active and identity
/// states without the modifier having to vend `animatableData` — which, on a
/// main-actor-isolated `ViewModifier`, it cannot do without an isolation hole.
struct FlipModifier: ViewModifier {
  var angle: Double
  var scale: Double
  var opacity: Double = 1

  func body(content: Content) -> some View {
    content
      .scaleEffect(scale)
      .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.35)
      .opacity(opacity)
  }
}

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
