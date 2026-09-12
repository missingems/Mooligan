import SwiftUI

/// Where the cards still to come sit relative to the one on top.
enum CardStackFrom {
  case none
  case top
  case bottom
  case left
  case right
}

/// The knobs `CardStackView` exposes, carrying its defaults across where they
/// still make sense at the size a Magic card is drawn.
struct CardStackSetting {
  /// Cards drawn at full strength, including the one on top. One more is always
  /// drawn behind these and faded in as the stack advances, so nothing pops
  /// into existence at the back.
  var visibleCount = 3

  /// Gap between one card in the stack and the next, along `stackFrom`.
  ///
  /// Larger than CardStackView's 4dp because our cards shrink by more than its
  /// samples do: the stagger has to beat the scale to peek out at all.
  var translationInterval: CGFloat = 22

  /// Size of each card relative to the one in front of it.
  var scaleInterval: CGFloat = 0.96

  /// How far the drag has to carry the card — as a fraction of *half* its width
  /// or height — before letting go throws it rather than springing it back.
  var swipeThreshold: CGFloat = 0.3

  /// Turn applied at a full card-width of travel, holding the very edge.
  var maxDegree: Double = 20

  var stackFrom: CardStackFrom = .bottom

  /// How long a thrown card takes to clear the screen.
  var swipeDuration: TimeInterval = 0.24

  /// How long a card takes to travel to a `CardStackLanding`. Longer than a
  /// throw off-screen, because this one is watched all the way in.
  var landingDuration: TimeInterval = 0.42

  /// How much darker each card is than the one in front of it.
  var dimInterval: Double = 0.06

  /// The way a card goes when nothing dragged it — the accessibility action, or
  /// any other route into the stack that is not a finger.
  var dealDirection = CGSize(width: -1, height: -0.18)
}

/// Where a thrown card comes to rest, instead of simply leaving the screen.
///
/// Given one, a card that is let go does not fly off into nothing — it travels
/// to a specific place at a specific size, which is what lets the pack's cards
/// tuck themselves into the strip along the bottom as they are dealt rather
/// than vanishing and reappearing there.
struct CardStackLanding: Equatable {
  /// Offset from the stack's own centre.
  var offset: CGSize
  /// Size relative to a card at rest.
  var scale: CGFloat
}

/// A stack of cards dealt off the top by dragging, modelled closely on
/// yuyakaido/CardStackView.
///
/// The three things it takes from that library, and why each one matters:
///
/// * The top card tracks the finger one-to-one in both axes and turns about the
///   point *opposite* where it was grabbed — take it by the top corner and it
///   swings one way, by the bottom corner and it swings the other. That single
///   detail is most of what separates a card that feels held from one that
///   feels scrolled.
/// * Everything behind it closes on the slot in front by exactly the fraction
///   the top card has travelled, so by the time a card is thrown the next one
///   is already sitting where it needs to be and the hand-off costs nothing.
/// * Letting go past `swipeThreshold` throws the card out along the way it was
///   going; short of it, it springs home.
///
/// Measurements are taken against the card rather than the screen, so the
/// gesture keeps the same weight whatever the card is sized to.
struct CardStack<Content: View>: View {
  let count: Int

  /// The frame one card occupies, and the yardstick the drag is measured
  /// against.
  let cardSize: CGSize

  var setting = CardStackSetting()

  /// Where a thrown card ends up. Without one it is thrown clear of the screen,
  /// which is CardStackView's own behaviour.
  var landing: CardStackLanding?

  /// The card on top. Written by the stack as cards are thrown; the host reads
  /// it to keep the rest of the screen in step.
  @Binding var topIndex: Int

  /// Mirror of how far the top card has travelled towards leaving, 0...1, kept
  /// in lockstep with the card itself — through the throw and the spring back
  /// alike — so the screen around the stack can move with it.
  @Binding var swipeProgress: CGFloat

  /// Bumped by the host to pull the last card thrown back onto the stack.
  var rewindToken = 0

  /// Bumped by the host to throw the top card without a drag, for the ways in
  /// which the pack gets driven that are not a finger.
  var dealToken = 0

  /// The drag has just reached the point where letting go would send the card
  /// away. Worth a tick, so the threshold can be felt rather than guessed at.
  var onThresholdCrossed: () -> Void = {}

  @ViewBuilder let content: (Int) -> Content

  /// Where a card was left once it was thrown, so a rewind can bring it back in
  /// along the path it went out by.
  private struct Departure {
    var translation: CGSize
    var rotation: Double
    var scale: CGFloat
  }

  /// Everything needed to place one card, computed in a single pass so that no
  /// card ever crosses a `ViewBuilder` branch: a card moving between the stack,
  /// the top slot and the pile of thrown cards has to stay the *same* view for
  /// SwiftUI to animate it rather than transition it, which is what makes
  /// rewind read as the throw running backwards.
  private struct Placement {
    var translation: CGSize = .zero
    var rotation: Double = 0
    var scale: CGFloat = 1
    var brightness: Double = 0
    var opacity: Double = 1
    var depth: Int = 0
  }

  private enum Motion {
    case idle
    case dragging
    case throwing
  }

  @State private var drag: CGSize = .zero

  /// Size of the card in hand. Only ever moves during a throw with a landing,
  /// where the card shrinks on its way to wherever it is going.
  @State private var throwScale: CGFloat = 1

  /// How far a throw has run, 0...1. Stands in for `ratio` while a card is in
  /// the air: a landing can sit closer than the distance `ratio` needs to reach
  /// 1, and the stack behind still has to finish closing up before the thrown
  /// card is retired.
  @State private var settleProgress: CGFloat = 0

  /// Where the card was taken hold of: +1 at its top edge, -1 at its bottom.
  @State private var grip: CGFloat = 0

  @State private var motion: Motion = .idle
  @State private var departures: [Int: Departure] = [:]
  @State private var isPastThreshold = false

  /// Tells one throw from the next, so a throw cut short by the following touch
  /// cannot have its completion handler land on the card that replaced it.
  @State private var flightID = 0

  var body: some View {
    ZStack {
      ForEach(renderedIndices, id: \.self) { index in
        card(at: index)
      }
    }
    .frame(width: cardSize.width, height: cardSize.height)
    .contentShape(.rect)
    .gesture(dragGesture)
    .onChange(of: rewindToken) { _, _ in rewind() }
    .onChange(of: dealToken) { _, _ in deal() }
  }

  // MARK: - Layout

  private var renderedIndices: [Int] {
    // One behind the top card, so a thrown card has somewhere to come back
    // from, and one past the visible stack, so the card about to enter it can
    // fade in rather than appear.
    let lower = max(0, topIndex - 1)
    let upper = min(count - 1, topIndex + setting.visibleCount)
    guard lower <= upper else { return [] }
    return Array(lower...upper)
  }

  private func card(at index: Int) -> some View {
    let placement = placement(at: index)

    return content(index)
      .frame(width: cardSize.width, height: cardSize.height)
      .brightness(placement.brightness)
      .scaleEffect(placement.scale)
      .rotationEffect(.degrees(placement.rotation))
      .offset(placement.translation)
      .opacity(placement.opacity)
      // A thrown card sits at depth -1 and so rides above the stack on its way
      // out, which is what it does in the hand.
      .zIndex(-Double(placement.depth))
      // The whole stack is dragged as one, from the frame the cards share.
      .allowsHitTesting(false)
  }

  private func placement(at index: Int) -> Placement {
    let depth = index - topIndex

    guard depth > 0 else {
      // The card in hand, and the one just thrown — parked where it flew to.
      let departure = departures[index] ?? Departure(
        translation: landing?.offset ?? flightVector(along: setting.dealDirection),
        rotation: 0,
        scale: landing?.scale ?? 1
      )

      return Placement(
        translation: depth == 0 ? drag : departure.translation,
        rotation: depth == 0 ? rotation(forWidth: drag.width) : departure.rotation,
        scale: depth == 0 ? throwScale : departure.scale,
        // A card that has landed is handed over to whatever it landed on and
        // stops being drawn here. It has to stay in the tree — a rewind brings
        // it back along the path it left by, and it fades in as it comes — but
        // leaving it drawn where it came to rest would sit a second copy of the
        // card on top of the thing that just took its place.
        opacity: depth < 0 ? 0 : 1,
        depth: depth
      )
    }

    // Behind: closing on the slot in front by however far the top card has
    // gone. CardStackView's own interpolation, verbatim.
    let progress = max(ratio, settleProgress)

    let currentScale = 1 - CGFloat(depth) * (1 - setting.scaleInterval)
    let nextScale = 1 - CGFloat(depth - 1) * (1 - setting.scaleInterval)

    let currentDistance = CGFloat(depth) * setting.translationInterval
    let nextDistance = CGFloat(depth - 1) * setting.translationInterval

    let currentDim = Double(depth) * setting.dimInterval
    let nextDim = Double(depth - 1) * setting.dimInterval

    return Placement(
      translation: stackOffset(currentDistance - (currentDistance - nextDistance) * progress),
      scale: currentScale + (nextScale - currentScale) * progress,
      brightness: -(currentDim - (currentDim - nextDim) * Double(progress)),
      // The card at the very back is drawn a step early and faded in by the
      // same ratio, so it has already arrived by the time the stack reaches it.
      opacity: depth > setting.visibleCount - 1 ? Double(progress) : 1,
      depth: depth
    )
  }

  private func stackOffset(_ distance: CGFloat) -> CGSize {
    switch setting.stackFrom {
    case .none: .zero
    case .top: CGSize(width: 0, height: -distance)
    case .bottom: CGSize(width: 0, height: distance)
    case .left: CGSize(width: -distance, height: 0)
    case .right: CGSize(width: distance, height: 0)
    }
  }

  // MARK: - Measurements

  /// CardStackView measures travel against *half* the card, on whichever axis
  /// the drag is dominated by. That halving is why a 30% threshold feels as
  /// light as it does.
  private func ratio(of translation: CGSize) -> CGFloat {
    guard cardSize.width > 0, cardSize.height > 0 else { return 0 }

    let dx = abs(translation.width)
    let dy = abs(translation.height)
    let ratio = dx < dy
      ? dy / (cardSize.height / 2)
      : dx / (cardSize.width / 2)

    return min(ratio, 1)
  }

  private var ratio: CGFloat { ratio(of: drag) }

  /// Positive turns the card clockwise. The `grip` term is the whole trick:
  /// dragging the top corner rightwards swings the card one way and dragging
  /// the bottom corner rightwards swings it the other, the way a card pinned at
  /// one end pivots about the other.
  private func rotation(forWidth width: CGFloat) -> Double {
    guard cardSize.width > 0 else { return 0 }
    return width * setting.maxDegree / cardSize.width * grip
  }

  /// CardStackView's `updateProportion`: +1 at the card's top edge, -1 at its
  /// bottom, 0 through the middle.
  private static func grip(atY y: CGFloat, cardHeight: CGFloat) -> CGFloat {
    guard cardHeight > 0 else { return 0 }
    let half = cardHeight / 2
    return min(max(-(y - half) / half, -1), 1)
  }

  // MARK: - Gesture

  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 1)
      .onChanged { value in
        guard topIndex < count else { return }

        if motion != .dragging {
          // Touching down mid-throw finishes that throw on the spot and hands
          // the finger the card underneath, so a run of quick swipes never has
          // to wait for the last one to land.
          if motion == .throwing { land() }
          guard topIndex < count else { return }

          motion = .dragging
          grip = Self.grip(atY: value.startLocation.y, cardHeight: cardSize.height)
          isPastThreshold = false
        }

        drag = value.translation
        swipeProgress = ratio

        let isPast = ratio >= setting.swipeThreshold
        if isPast != isPastThreshold {
          isPastThreshold = isPast
          if isPast { onThresholdCrossed() }
        }
      }
      .onEnded { value in
        guard motion == .dragging else { return }

        // Distance alone is CardStackView's test. On a touchscreen a short
        // flick reads as every bit as deliberate as a long haul, so where the
        // finger was *heading* counts as well.
        let isThrown = ratio >= setting.swipeThreshold
          || ratio(of: value.predictedEndTranslation) >= setting.swipeThreshold

        if isThrown {
          throwOut(along: value.predictedEndTranslation)
        } else {
          springBack()
        }
      }
  }

  // MARK: - Transitions

  private func throwOut(along direction: CGSize) {
    motion = .throwing
    isPastThreshold = false
    flightID += 1
    let flight = flightID

    // A card with somewhere to go travels there and shrinks to fit; one
    // without is thrown clear of the screen.
    let target = landing?.offset ?? flightVector(along: direction)
    let scale = landing?.scale ?? 1

    // Landing somewhere on screen is a shorter, gentler move than being thrown
    // off it, and wants an easing that settles rather than one that launches.
    let animation: Animation =
      landing == nil
        ? .easeOut(duration: setting.swipeDuration)
        : .spring(duration: setting.landingDuration, bounce: 0.12)

    withAnimation(animation) {
      drag = target
      throwScale = scale
      settleProgress = 1
      swipeProgress = 1
    } completion: {
      guard flight == flightID else { return }
      land()
    }
  }

  /// How far a thrown card is sent, and which way.
  private func flightVector(along direction: CGSize) -> CGSize {
    // Comfortably past the edge of any screen the card fits on. Overshooting is
    // deliberate: `ratio` caps at 1 a long way short of this, so the stack has
    // finished closing up well before the card lands, and the card is out of
    // sight within the first fraction of the animation.
    let reach = hypot(cardSize.width, cardSize.height) * 2.2

    // `predictedEndTranslation` can come back at nothing for a drag that ended
    // dead still; the travel already on the clock is the better guide then.
    let source = hypot(direction.width, direction.height) > 1 ? direction : drag
    let length = hypot(source.width, source.height)
    guard length > 1 else { return CGSize(width: reach, height: 0) }

    return CGSize(
      width: source.width / length * reach,
      height: source.height / length * reach
    )
  }

  /// The thrown card is gone: park it where it flew to and let the stack take
  /// its place.
  ///
  /// Nothing moves on screen. `ratio` reached 1 early in the flight, so the
  /// card behind is already sitting exactly where the top card is about to be,
  /// and every card's placement works out identical either side of this.
  private func land() {
    guard topIndex < count else { return }

    // Retires any throw still in the air, including the one being landed here.
    flightID += 1

    departures[topIndex] = Departure(
      translation: drag,
      rotation: rotation(forWidth: drag.width),
      scale: throwScale
    )

    topIndex += 1
    drag = .zero
    throwScale = 1
    settleProgress = 0
    swipeProgress = 0
    motion = .idle
  }

  private func springBack() {
    motion = .idle
    isPastThreshold = false

    withAnimation(.spring(duration: 0.42, bounce: 0.3)) {
      drag = .zero
      throwScale = 1
      settleProgress = 0
      swipeProgress = 0
    }
  }

  /// The way a card leaves when nothing dragged it: the same throw, aimed off
  /// to the left and given enough of a grip to turn on its way out.
  private func deal() {
    guard topIndex < count, motion != .throwing else { return }

    motion = .idle
    grip = 0.5
    throwOut(along: setting.dealDirection)
  }

  /// Pull the last card thrown back onto the stack. It comes in from wherever
  /// it left, so the undo reads as the throw running backwards.
  private func rewind() {
    guard topIndex > 0, motion == .idle else { return }

    withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
      topIndex -= 1
    }
  }
}
