import DesignComponents
import Networking
import SwiftUI

/// The sealed pack, and the drag that opens it.
///
/// The tear is deliberately kept out of the store: the drag redraws at display
/// rate, and routing every frame through a reducer would be both slower and
/// noisier than it is worth. Only the moment the pack gives way is an action.
struct PackTearView: View {
  let pack: BoosterPack

  /// `true` once the reducer has accepted the tear, which is the cue for the
  /// strip to fly off and the cards to come out.
  let isOpening: Bool

  let onTearCompleted: () -> Void

  @State private var progress: CGFloat = 0
  @State private var dragOrigin: CGFloat?
  @State private var isDragging = false
  @State private var haptics = PackHaptics()
  @State private var art = PackWrapperArtLoader()

  /// The space the tear has to work in. Seeded so the first pass draws
  /// something sensible; corrected on the first measurement.
  @State private var viewSize = CGSize(width: 393, height: 780)

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Past this the pack is committed: letting go finishes the tear rather than
  /// springing back.
  private static let commitThreshold: CGFloat = 0.78

  private var theme: PackTheme {
    PackTheme(setCode: pack.product.set.code, kind: pack.product.kind)
  }

  private var seed: UInt64 {
    pack.id.uuidString.unicodeScalars.reduce(UInt64(1_099_511_628_211)) { partial, scalar in
      (partial ^ UInt64(scalar.value)) &* 0x1000_0000_01B3
    }
  }

  var body: some View {
    let packWidth = min(viewSize.width * 0.68, 320)
    // Sized to the photograph's own ratio when there is one, so the torn shapes
    // cut across what is actually drawn rather than a slightly different box.
    let ratio = art.aspectRatio ?? PackGeometry.widthToHeight
    let packSize = CGSize(width: packWidth, height: packWidth / ratio)

    return ZStack {
      cardsPeeking(packSize: packSize)
      wrapper(packSize: packSize)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(Rectangle())
    .gesture(tearGesture(packWidth: packWidth))
    // Measured, not laid out. A `GeometryReader` would take the space and hand
    // its children a proposal of its own; the tear only needs to know how wide
    // the screen is in order to size the pack.
    .onGeometryChange(for: CGSize.self) { $0.size } action: { viewSize = $0 }
    .onAppear { haptics.prepare() }
    .task { await art.load(for: pack.product) }
    .task { await demonstrateTear() }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Sealed \(pack.product.kind.title) from \(pack.product.set.name)")
    .accessibilityHint("Swipe right to left across the pack to tear it open")
    .accessibilityAddTraits(.isButton)
    .accessibilityAction { complete() }
    .accessibilityIdentifier("packOpening.tear")
  }

  // MARK: - Wrapper

  @ViewBuilder
  private func wrapper(packSize: CGSize) -> some View {
    let strip = TornStripShape(seed: seed, progress: progress, baseline: PackGeometry.tearBaseline)
    let body = TornBodyShape(seed: seed, progress: progress, baseline: PackGeometry.tearBaseline)
    let crimp = CrimpedRectangle(
      toothWidth: PackGeometry.crimpToothWidth,
      toothDepth: PackGeometry.crimpDepth
    )

    // A photograph already has its crimped edges printed into it; clipping the
    // drawn crimp over the top would serrate it twice.
    let stripClip: AnyShape =
      art.photo == nil ? AnyShape(strip.intersection(crimp)) : AnyShape(strip)
    let bodyClip: AnyShape =
      art.photo == nil ? AnyShape(body.intersection(crimp)) : AnyShape(body)

    ZStack {
      // Lower two thirds: still holding the cards, and sagging open a little as
      // the seal goes.
      artwork
        .frame(width: packSize.width, height: packSize.height)
        .clipShape(bodyClip)
        .rotation3DEffect(
          .degrees(reduceMotion ? 0 : Double(progress) * 5),
          axis: (x: 1, y: 0, z: 0),
          anchor: .bottom,
          perspective: 0.4
        )

      // The strip that comes away, lifting and twisting out of the way as the
      // tear runs and then thrown clear once the pack is open.
      artwork
        .frame(width: packSize.width, height: packSize.height)
        .clipShape(stripClip)
        .rotationEffect(
          .degrees(reduceMotion ? 0 : Double(progress) * -7 + (isOpening ? -22 : 0)),
          anchor: .bottomLeading
        )
        .offset(
          x: isOpening ? packSize.width * 1.4 : progress * packSize.width * 0.06,
          y: isOpening ? -packSize.height * 0.7 : -progress * packSize.height * 0.05
        )
        .opacity(isOpening ? 0 : 1)
        .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
    }
    .frame(width: packSize.width, height: packSize.height)
    .rotationEffect(.degrees(isDragging && reduceMotion == false ? 1.5 : 0))
    .shadow(color: .black.opacity(0.5), radius: 24, y: 16)
    .animation(.spring(duration: 0.55, bounce: 0.25), value: isOpening)
    .animation(.snappy(duration: 0.2), value: isDragging)
  }

  @ViewBuilder
  private var artwork: some View {
    if let photo = art.photo {
      photo
        .resizable()
        .aspectRatio(contentMode: .fill)
    } else {
      BoosterPackArtwork(product: pack.product, theme: theme)
    }
  }

  // MARK: - Cards behind the wrapper

  /// The cards themselves, showing through the widening gap.
  ///
  /// These used to be blank white rectangles standing in for "the edge you see
  /// before the first card comes out". The pack has already downloaded every
  /// card it contains by the time it can be torn, so there is no reason to show
  /// a placeholder: the real cards peek out instead, which turns the rip into a
  /// glimpse of what is inside rather than a look at some white card stock.
  ///
  /// Deliberately the first cards of the reveal order, which is filler-first —
  /// the pack gives away its commons here, never its rare.
  private func cardsPeeking(packSize: CGSize) -> some View {
    let lift = progress * packSize.height * 0.1
    let cardWidth = packSize.width * 0.84
    let cardHeight = cardWidth / MagicCardImageRatio.widthToHeight.rawValue
    let peeking = Array(pack.revealOrder.prefix(3))

    return ZStack {
      ForEach(Array(peeking.enumerated()), id: \.element.id) { index, pulled in
        PulledCardImage(pulled: pulled, width: cardWidth)
          .rotationEffect(.degrees(Double(index - 1) * 2.5))
          .offset(
            y: packSize.height * 0.17 - lift - CGFloat(index) * 3
              + cardHeight / 2 - packSize.height / 2
          )
          .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
          // The first card of the pack sits at the front of the fan.
          .zIndex(-Double(index))
      }
    }
    .frame(width: packSize.width, height: packSize.height)
    .opacity(progress > 0.04 ? 1 : 0)
  }

  // MARK: - Affordance

  /// Nudges the seal open every few seconds until the reader takes over.
  ///
  /// This replaces a pill reading "Tear" with a chevron, pinned at the height
  /// the tear runs. The pack photograph is shot at a slight angle, so a marker
  /// placed on a horizontal line never sat where the pack's own seal is — and
  /// it pointed at one spot when the drag in fact works from anywhere, which
  /// made it read as an instruction the pack then failed to follow. Showing a
  /// little of the real rip says the same thing with none of that: it is the
  /// gesture itself, in miniature, in the right place by construction.
  private func demonstrateTear() async {
    guard reduceMotion == false else { return }

    while Task.isCancelled == false {
      try? await Task.sleep(for: .seconds(2.4))

      guard isDragging == false, isOpening == false, progress == 0 else { continue }
      withAnimation(.easeOut(duration: 0.5)) { progress = 0.1 }

      try? await Task.sleep(for: .milliseconds(620))

      guard isDragging == false, isOpening == false else { continue }
      withAnimation(.easeInOut(duration: 0.45)) { progress = 0 }
    }
  }

  // MARK: - Gesture

  private func tearGesture(packWidth: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 4)
      .onChanged { value in
        guard isOpening == false else { return }

        if dragOrigin == nil {
          dragOrigin = value.startLocation.x
          isDragging = true
          haptics.beginRumble()
        }

        // Right to left, mapped over roughly one pack width of travel.
        let travelled = (dragOrigin ?? value.startLocation.x) - value.location.x
        let newProgress = min(max(travelled / (packWidth * 0.9), 0), 1)

        progress = newProgress
        haptics.updateRumble(progress: Double(newProgress))

        if newProgress >= 0.97 {
          complete()
        }
      }
      .onEnded { _ in
        guard isOpening == false else { return }
        isDragging = false
        dragOrigin = nil

        if progress >= Self.commitThreshold {
          complete()
        } else {
          haptics.cancelRumble()
          withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
            progress = 0
          }
        }
      }
  }

  private func complete() {
    guard isOpening == false else { return }

    isDragging = false
    dragOrigin = nil
    haptics.completeRumble()

    withAnimation(.easeOut(duration: 0.18)) {
      progress = 1
    }

    onTearCompleted()
  }
}
