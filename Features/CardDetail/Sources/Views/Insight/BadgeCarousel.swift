import SwiftUI
import DesignComponents

/// The badges of every tile in a row above the insight pages, all one size and side by side: the
/// one on show in the middle, its neighbours fainter and peeking in at the edges, the row sliding
/// along with the pages under the finger so the next badge comes into the middle with its page.
///
/// The badge the pager opened on spins in, like an award in the Fitness app, and the one in the
/// middle floats, as the scrub's hovering card does, with a reflection sliding over it.
///
/// Its own view so that the pages' scroll, which moves `position` on every frame of a swipe, redraws
/// the badges and not the pages under them.
struct BadgeCarousel: View, Equatable {
  let widgets: [InformationWidget]
  /// The pages' scroll in pages, fractional mid-swipe. A binding, so that only this view reads it.
  @Binding var position: Double
  let opened: InformationWidget
  let onSelect: (InformationWidget) -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  /// Degrees the opened badge is turned away. It starts three quarters of a turn round, edge on, and
  /// spins in with the overlay already there to see it.
  @State private var spin = 270.0
  /// How far into its float the middle badge is, eased in once the spin has done its work.
  @State private var float = 0.0
  /// Each badge's width as drawn, measured, so the badges sit an even gap apart however wide each
  /// one is. Until it is measured a badge is taken to be as wide as a typical one.
  @State private var widths: [InformationWidget: CGFloat] = [:]

  /// `onSelect` is left out: a closure is never equal to another, and it only hands a tapped badge
  /// on. `position` redraws this view through the binding whenever the pages move.
  nonisolated static func == (lhs: BadgeCarousel, rhs: BadgeCarousel) -> Bool {
    lhs.widgets == rhs.widgets && lhs.opened == rhs.opened
  }

  var body: some View {
    let centres = centres
    let middle = centre(at: position, in: centres)

    ZStack {
      ForEach(Array(widgets.enumerated()), id: \.element) { index, widget in
        let distance = Double(index) - position
        // Only the few near the middle are drawn; the rest are well off either edge.
        if abs(distance) < 3 {
          badge(widget, distance: distance)
            .opacity(1 - min(abs(distance), 1) * 0.45)
            .offset(x: centres[index] - middle)
            .onTapGesture { onSelect(widget) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(widget.insightTitle))
            .accessibilityAddTraits(abs(distance) < 0.5 ? [.isButton, .isSelected] : .isButton)
            .accessibilityIdentifier("cardDetail.insight.badge.\(widget.name)")
        }
      }
    }
    .frame(height: 170.0)
    .frame(maxWidth: .infinity)
    .onAppear {
      guard reduceMotion == false else {
        spin = 0
        return
      }
      // Underdamped, so it swings about a dozen degrees past facing and back, as the badge in the
      // Fitness app does. Started from far enough round that most of the turn happens after the
      // overlay has faded in: from edge on, the whole turn was over inside the fade.
      withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) {
        spin = 0
      }
      withAnimation(.easeInOut(duration: 1.2).delay(0.6)) {
        float = 1
      }
    }
  }

  /// Where each badge's middle sits along the row, the badges side by side an even gap apart.
  private var centres: [CGFloat] {
    var centres: [CGFloat] = []
    var x: CGFloat = 0
    for widget in widgets {
      let width = widths[widget] ?? 130
      centres.append(x + width / 2)
      x += width + 28
    }
    return centres
  }

  /// The point along the row at the middle of the screen: a badge's middle when the pages rest on
  /// its page, and part way from one to the next mid-swipe.
  private func centre(at position: Double, in centres: [CGFloat]) -> CGFloat {
    guard let last = centres.indices.last else { return 0 }
    let clamped = min(max(position, 0), Double(last))
    let lower = Int(clamped.rounded(.down))
    let upper = min(lower + 1, last)
    return centres[lower] + (centres[upper] - centres[lower]) * CGFloat(clamped - Double(lower))
  }

  private func badge(_ widget: InformationWidget, distance: Double) -> some View {
    // Only the badge in the middle floats and follows the phone; it hands the float over as the next
    // one comes in.
    HoverTilt(amount: float * max(0, 1 - abs(distance) * 2), isActive: abs(distance) < 0.5) { pose in
      BadgeSpin(angle: widget == opened ? spin : 0, front: face(widget), back: back(widget))
        .environment(\.hoverPose, pose)
    }
  }

  @ViewBuilder private func face(_ widget: InformationWidget) -> some View {
    if case let .pullOdds(odds, rarity, tilt) = widget {
      OddsSticker(packs: odds.estimatePacks ?? 1, rarity: rarity, size: 44.0, tilt: tilt)
        .equatable()
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { widths[widget] = $0 }
    } else {
      // The tile as it sits in the row, larger, as a badge. The scale leaves its layout size alone, so
      // the padding makes the room it grows into, and its width is measured before it and scaled.
      Widget(kind: widget, isBadge: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { widths[widget] = $0 * 1.6 }
        .overlay {
          MotionSheen(intensity: 0.4)
            .mask(Capsule())
        }
        .scaleEffect(1.6)
        .padding(.vertical, 21.0)
    }
  }

  /// What a badge shows while it is turned away: the sticker's backing, or the badge's blank face.
  @ViewBuilder private func back(_ widget: InformationWidget) -> some View {
    if case let .pullOdds(odds, rarity, tilt) = widget {
      OddsSticker(packs: odds.estimatePacks ?? 1, rarity: rarity, size: 44.0, tilt: tilt, isBack: true)
        .equatable()
    } else {
      // The tile hidden, for its size only: covering its face instead let the face show through the
      // cover while the overlay was still fading in, since the fade reaches each layer on its own.
      Widget(kind: widget, isBadge: true)
        .hidden()
        .overlay {
          Capsule()
            .fill(Color(.secondarySystemBackground))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
        }
        .scaleEffect(1.6)
        .padding(.vertical, 21.0)
    }
  }
}
