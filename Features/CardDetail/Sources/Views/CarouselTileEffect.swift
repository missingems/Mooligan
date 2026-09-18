import DesignComponents
import SwiftUI

/// Where one strip card sits and how it is drawn: the lean away from the card under the glass, the
/// glass's magnification, and the bend around the ends.
///
/// Animatable on the lean so a change to it is stepped here, one frame at a time, with the offset and
/// the shaders worked out together from the same value. Animated from outside, SwiftUI moved the offset
/// but could not step the shaders' arguments, and dropped the card until the next plain update: the
/// cards either side of the glass vanished for the whole landing.
struct CarouselTileEffect: ViewModifier, Animatable {
  var parting: CGFloat
  let scrollWidth: CGFloat
  let zone: CGFloat
  let radius: CGFloat

  nonisolated var animatableData: CGFloat {
    get { parting }
    set { parting = newValue }
  }

  func body(content: Self.Content) -> some View {
    content.visualEffect { [parting, scrollWidth, zone, radius] effect, geometry in
      Self.effect(
        effect,
        geometry: geometry,
        parting: parting,
        scrollWidth: scrollWidth,
        zone: zone,
        radius: radius
      )
    }
  }

  private nonisolated static func effect(
    _ content: EmptyVisualEffect,
    geometry: GeometryProxy,
    parting: CGFloat,
    scrollWidth: CGFloat,
    zone: CGFloat,
    radius: CGFloat
  ) -> some VisualEffect {
    let frame = geometry.frame(in: .scrollView(axis: .horizontal))
    let minX = frame.minX + max(0, (scrollWidth - 48.0) / 2)
    // Everything either side of the middle leans away from it, which widens only the two gaps
    // around the card under the glass. A visual offset, so the strip still snaps on its even
    // spacing.
    let lean = min(max((minX + frame.width / 2 - scrollWidth / 2) / 48.0, -1), 1) * parting
    // The lean belongs to where the card sits, so the bend has to read it as the card's own
    // origin. Left out of that origin, the edge shader samples a card the lean's width away from
    // itself and the end cards come out sliced.
    let leanedMinX = minX + lean
    let center = leanedMinX + frame.width / 2
    let depth = max(0, zone - center, center - (scrollWidth - zone))
    let bend = min(depth / radius, .pi / 2)
    let curl = (center < scrollWidth / 2 ? 1 : -1) * (depth - radius * sin(bend))
    let lensCenter = scrollWidth / 2 - (leanedMinX + curl)

    return content
      .layerEffect(
        ShaderLibrary.designComponents.carouselMagnify(
          .float2(CGPoint(x: lensCenter, y: geometry.size.height / 2)),
          .float2(CGSize(width: 64.0, height: 48.0)),
          .float(11),
          .float(1.5),
          .float2(CGSize(width: 0.6875, height: 0.6875))
        ),
        // Room to draw the whole glass from any card under it. Mid-scrub the glass sits off a
        // card's centre by up to half a slot, and with only 16pt to spare the part past that came
        // out as bare bar.
        maxSampleOffset: CGSize(width: 48, height: 8),
        isEnabled: abs(lensCenter - frame.width / 2) < 96
      )
      .layerEffect(
        ShaderLibrary.designComponents.carouselEdge(
          .float(leanedMinX + curl),
          .float(leanedMinX),
          .float(scrollWidth),
          .float(geometry.size.height),
          .float(zone)
        ),
        maxSampleOffset: CGSize(width: zone, height: 26),
        isEnabled: leanedMinX < zone || leanedMinX + frame.width > scrollWidth - zone
      )
      .offset(x: lean + curl)
  }
}
