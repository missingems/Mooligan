#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// A card at either end of the strip curls away round a cylinder, the way a real card bends in the
// hand: it narrows as it turns (the unrolled position of each pixel comes back through `asin`), and
// the further round it has turned, the further from the eye it is, so perspective makes it shorter
// too. Both follow the one angle, so the card's own edges stay straight and taper smoothly towards the
// horizon, and it darkens as it faces away. Nothing clips it: cut by the bar's rounded end instead,
// the card picked up a circular corner the moment it reached it. The softening is the strip's own
// variable blur laid over both ends, not done here: a handful of samples per pixel made the edges
// grainy.
[[ stitchable ]] half4 carouselEdge(float2 position, SwiftUI::Layer layer, float origin, float flatOrigin, float width, float height, float zone) {
  float radius = 2.0 * zone / M_PI_F;
  float x = origin + position.x;
  float flat = x;
  float turn = 0.0;

  if (x < zone) {
    turn = (zone - x) / radius;
    if (turn >= 1.0) {
      return half4(0.0);
    }
    flat = zone - radius * asin(turn);
  } else if (x > width - zone) {
    turn = (x - (width - zone)) / radius;
    if (turn >= 1.0) {
      return half4(0.0);
    }
    flat = width - zone + radius * asin(turn);
  }

  if (turn <= 0.0) {
    // Sampled the same way as the path below, not by this pixel's own position: a card that starts
    // bending part way along would otherwise show a hard seam where the two meet.
    return layer.sample(float2(x - flatOrigin, position.y));
  }

  // `turn` is the sine of the angle the card has curled through; the depth it has gone back is what
  // the cosine gives up. Seen from a camera a few radii away, height shrinks with that depth.
  float away = 1.0 - sqrt(max(1.0 - turn * turn, 0.0));
  float shrink = 1.0 / (1.0 + 0.3 * away);
  float halfHeight = height * 0.5;
  float sourceY = halfHeight + (position.y - halfHeight) / shrink;
  if (sourceY < 0.0 || sourceY > height) {
    return half4(0.0);
  }

  half4 color = layer.sample(float2(flat - flatOrigin, sourceY));
  color.rgb *= half(1.0 - 0.45 * turn);
  return color;
}
