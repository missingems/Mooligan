#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Magnifies the part of one strip card that falls under the glass, in place. The strip stays a
// single row of cards: each card bends its own pixels where the glass covers it, rather than the
// glass drawing a second copy of the row over the first.
[[ stitchable ]] half4 carouselMagnify(
  float2 position,
  SwiftUI::Layer layer,
  float2 lensCenter,
  float2 lensSize,
  float radius,
  float zoom,
  float2 rimScale
) {
  float2 offset = position - lensCenter;
  float2 halfLens = lensSize * 0.5;

  float2 corner = abs(offset) - halfLens + radius;
  float distance = length(max(corner, 0.0)) + min(max(corner.x, corner.y), 0.0) - radius;
  if (distance > 0.5) {
    return layer.sample(position);
  }

  // One continuous lens across the whole glass, the way a real magnifier is ground: strongest in
  // the middle and easing off smoothly towards the rim, so anything straight passing underneath
  // bows into a single smooth curve. Measured on rings that follow the glass's own shape
  // (|x|^4 + |y|^4), 0 in the middle and 1 at every edge, so the rim scale still lands the card's
  // edge exactly on the glass's. Tying the bend to the distance from the nearest edge instead made
  // the middle flat and put every bit of bending in the last few points: straight in the middle,
  // then a kink at the rim.
  float2 unit = offset / halfLens;
  float2 square = unit * unit;
  float ring = min(sqrt(square.x * square.x + square.y * square.y), 1.1);
  float2 scale = rimScale / zoom * (1.0 + (zoom - 1.0) * ring);

  // Colour splits the way it does through real glass: nothing on the axis, growing towards the rim.
  float fringe = 0.022 * ring;
  half4 green = layer.sample(lensCenter + offset * scale);
  half4 red = layer.sample(lensCenter + offset * scale * (1.0 + fringe));
  half4 blue = layer.sample(lensCenter + offset * scale * (1.0 - fringe));
  half4 magnified = half4(red.r, green.g, blue.b, green.a);

  return mix(layer.sample(position), magnified, half(1.0 - smoothstep(-0.5, 0.5, distance)));
}
