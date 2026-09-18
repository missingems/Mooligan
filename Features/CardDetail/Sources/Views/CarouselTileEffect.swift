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
    let tile = CarouselTileGeometry(
      frame: geometry.frame(in: .scrollView(axis: .horizontal)),
      parting: parting,
      scrollWidth: scrollWidth,
      zone: zone,
      radius: radius
    )

    return content
      .layerEffect(
        ShaderLibrary.designComponents.carouselMagnify(
          .float2(CGPoint(x: tile.lensCenter, y: geometry.size.height / 2)),
          .float2(CGSize(width: 64.0, height: 48.0)),
          .float(11),
          .float(1.5),
          .float2(CGSize(width: 0.6875, height: 0.6875))
        ),
        // Room to draw the whole glass from any card under it. Mid-scrub the glass sits off a
        // card's centre by up to half a slot, and with only 16pt to spare the part past that came
        // out as bare bar.
        maxSampleOffset: CGSize(width: 48, height: 8),
        isEnabled: tile.isNearLens
      )
      .layerEffect(
        ShaderLibrary.designComponents.carouselEdge(
          .float(tile.leanedMinX + tile.curl),
          .float(tile.leanedMinX),
          .float(scrollWidth),
          .float(geometry.size.height),
          .float(zone)
        ),
        maxSampleOffset: CGSize(width: zone, height: 26),
        isEnabled: tile.isInEndZone
      )
      .offset(x: tile.lean + tile.curl)
  }
}
