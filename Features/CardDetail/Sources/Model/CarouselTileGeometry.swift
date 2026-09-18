import Foundation

/// Where one strip card sits and bends, worked out from its frame in the strip's scroll view: the
/// lean away from the card under the glass, the curl round the ends, and which of the two shaders
/// the card needs.
struct CarouselTileGeometry: Equatable, Sendable {
  let minX: CGFloat
  let lean: CGFloat
  let leanedMinX: CGFloat
  let depth: CGFloat
  let bend: CGFloat
  let curl: CGFloat
  let lensCenter: CGFloat
  let isNearLens: Bool
  let isInEndZone: Bool

  init(frame: CGRect, parting: CGFloat, scrollWidth: CGFloat, zone: CGFloat, radius: CGFloat) {
    minX = frame.minX + max(0, (scrollWidth - 48.0) / 2)
    // Everything either side of the middle leans away from it, which widens only the two gaps
    // around the card under the glass. A visual offset, so the strip still snaps on its even
    // spacing.
    lean = min(max((minX + frame.width / 2 - scrollWidth / 2) / 48.0, -1), 1) * parting
    // The lean belongs to where the card sits, so the bend has to read it as the card's own
    // origin. Left out of that origin, the edge shader samples a card the lean's width away from
    // itself and the end cards come out sliced.
    leanedMinX = minX + lean
    let center = leanedMinX + frame.width / 2
    depth = max(0, zone - center, center - (scrollWidth - zone))
    bend = min(depth / radius, .pi / 2)
    curl = (center < scrollWidth / 2 ? 1 : -1) * (depth - radius * sin(bend))
    lensCenter = scrollWidth / 2 - (leanedMinX + curl)
    isNearLens = abs(lensCenter - frame.width / 2) < 96
    isInEndZone = leanedMinX < zone || leanedMinX + frame.width > scrollWidth - zone
  }
}
