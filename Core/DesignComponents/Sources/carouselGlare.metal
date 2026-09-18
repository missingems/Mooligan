#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// The glass itself: what it reflects, not what it magnifies. Drawn over the strip as its own layer,
// so it covers the card under the glass and the page either side of the toolbar alike.
//
// A reflection on curved glass sits wherever the surface faces halfway between the light and the eye,
// so when the phone tilts it slides round the curve instead of across the glass. Everything that lives
// on the rim is placed by its angle around the middle, measured from the light, and only the reflection
// on the flat face moves across it, and only a little.
[[ stitchable ]] half4 carouselGlare(float2 position, half4 color, float2 size, float radius, float2 light) {
  float2 halfSize = size * 0.5;
  float2 offset = position - halfSize;

  float2 corner = abs(offset) - halfSize + radius;
  float distance = length(max(corner, 0.0)) + min(max(corner.x, corner.y), 0.0) - radius;
  if (distance > 0.5) {
    return half4(0.0h);
  }
  float coverage = 1.0 - smoothstep(-0.5, 0.5, distance);
  // 0 in the middle to 1 at the edge, the same width in points all the way round.
  float reach = clamp(1.0 + distance / min(halfSize.x, halfSize.y), 0.0, 1.0);
  float2 unit = offset / halfSize;

  // Which way round the glass a point is, and how far out on rings that follow the rounded corners
  // (|x|^4 + |y|^4). The rings stay smooth all the way in, where the distance field creases along the
  // diagonals, and round the corners more softly than the edge does, so what sits inside the rim uses
  // them.
  float2 around = unit * rsqrt(max(dot(unit, unit), 1e-8));
  float2 square = unit * unit;
  float level = sqrt(sqrt(square.x * square.x + square.y * square.y));

  // The light: above the glass at rest, turned by the tilt. How far the tilt leans it decides how deep
  // into the curve its reflection sits. The upward part is held short of zero, so the light never
  // passes straight in front, where its direction would flip.
  float2 toward = float2(light.x * 3.0, min(light.y * 3.0 - 1.0, -0.35));
  float lean = length(toward);
  float2 sun = toward / lean;
  // Turns a direction measured from straight up into the same direction measured from the light.
  float2x2 turn = float2x2(float2(-sun.y, sun.x), float2(-sun.x, -sun.y));
  float facing = dot(around, sun);

  // The profile: flat across the middle, rounding over at the rim like a squircle, (1 - x^4)^(1/4),
  // so the surface turns away from the eye only near the edge, and glass reflects most where it turns
  // furthest (Schlick's Fresnel term, the base reflectance left to the face's own highlights).
  float bend = reach * reach * reach;
  float flat = max(1.0 - bend * reach, 0.0);
  float rise = sqrt(flat) * sqrt(sqrt(flat));
  float grazing = 1.0 - rise * rsqrt(bend * bend + rise * rise);
  float fresnel = grazing * grazing * grazing * grazing * grazing;
  float rim = smoothstep(0.62, 1.0, reach);

  // Two highlights across the top rather than one in a corner, the way a domed glass catches a room's
  // light twice. Each keeps its angle from the light as the light turns, so they travel round the rim
  // together, and they sit further out on the curve the further the tilt leans the light.
  float depth = clamp(0.62 + (lean - 1.0) * 0.13, 0.5, 0.8);
  float2 wideAt = turn * float2(-0.5145, -0.8575);
  float2 narrowAt = turn * float2(0.3765, -0.9264);
  float wideAcross = level - depth;
  float narrowAcross = level - depth - 0.025;
  float speculars = exp(-(1.0 - dot(around, wideAt)) * 2.2 - wideAcross * wideAcross * 13.6) * 0.9
    + exp(-(1.0 - dot(around, narrowAt)) * 4.9 - narrowAcross * narrowAcross * 21.2) * 0.55;

  // The bright room caught along the rim on the light's side and the darker floor on the other,
  // turning with the light.
  float top = (rim * 0.75 + fresnel * 0.25) * smoothstep(-0.1, 0.9, facing);
  float bottom = rim * smoothstep(0.0, 0.9, -facing);

  // A window across the face. A flat reflection has no curve to slide round, so it drifts with the
  // tilt instead, but only a little, the face being nearly level.
  float2 face = unit - light * 0.7;
  float sweep = face.y - face.x * 0.3 + 0.44;
  float streak = exp(-sweep * sweep * 5.3);

  // The light the glass splits: an arc along the rim on the light's side, weighted to it because a band
  // all the way round reads as fringing on the picture. The colours run along the arc from the light's
  // own angle, so the spectrum turns with it rather than staying painted on the glass.
  float band = level - clamp(0.75 + (lean - 1.0) * 0.06, 0.7, 0.82);
  float arc = exp(-band * band * 42.0) * smoothstep(-0.2, 0.9, facing);
  float hue = atan2(sun.x * around.y - sun.y * around.x, facing + 1e-6) * 0.28 + 0.06;
  half3 spectrum = half3(
    half(0.5 + 0.5 * cos(6.283 * hue)),
    half(0.5 + 0.5 * cos(6.283 * (hue - 0.333))),
    half(0.5 + 0.5 * cos(6.283 * (hue - 0.666)))
  );

  // Laid over one another rather than added: reflected light washes out what is behind it before it
  // tints it, and added as colour alone the arc disappeared into a busy card.
  half dark = half(bottom * 0.18);
  half4 result = half4(0.0h, 0.0h, 0.0h, dark);
  // Where the highlights, the rim and the arc land on one spot, they ease off past 0.25 instead of
  // adding up, and can never pass 0.35.
  float shine = streak * 0.07 + speculars * 0.22 + top * 0.2 + arc * 0.1;
  float excess = max(shine - 0.25, 0.0);
  half white = half(min(shine, 0.25) + excess / (1.0 + excess * 10.0));
  result = half4(white, white, white, white) + result * (1.0h - white);
  half tint = half(arc * 0.16);
  result = half4(spectrum * tint, tint) + result * (1.0h - tint);

  return result * half(coverage);
}
