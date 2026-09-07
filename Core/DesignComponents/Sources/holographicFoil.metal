//
//  holographicFoil.metal
//  DesignComponents
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Iridescent foil, as seen on a booster wrapper or a traditional foil card.
///
/// Three layers stacked on top of whatever the view already drew:
///   1. interference bands, which give foil its rainbow;
///   2. one bright specular streak that travels as the device tilts;
///   3. a fine crinkle, so the surface reads as plastic rather than glass.
///
/// `tilt` is the device roll in radians and `time` a slow clock, so the sheen
/// moves both when the phone moves and when it is sitting still.
[[ stitchable ]] half4 holographicFoil(
  float2 position,
  half4 color,
  float2 bounds,
  float time,
  float tilt,
  float intensity
) {
  if (bounds.x <= 0.0 || bounds.y <= 0.0) {
    return color;
  }

  half alpha = color.a;
  if (alpha <= 0.001h) {
    return color;
  }

  // SwiftUI hands us premultiplied colour; work in straight alpha and
  // re-premultiply on the way out.
  half3 base = color.rgb / alpha;

  float2 uv = position / bounds;

  // Diagonal sweep coordinate. Tilt shifts it, so the rainbow slides when the
  // phone rolls; time keeps it alive when the phone is flat on a table.
  float sweep = (uv.x * 0.75 + uv.y * 0.45) + tilt * 0.55 + time * 0.05;

  // 1. Interference bands.
  float band = sweep * 11.0;
  half3 rainbow = half3(
    0.5h + 0.5h * half(sin(band)),
    0.5h + 0.5h * half(sin(band + 2.0944)),
    0.5h + 0.5h * half(sin(band + 4.1888))
  );

  // 2. Specular streak: one narrow, very bright line crossing the surface.
  float streakPhase = fract(sweep * 0.55);
  float streak = smoothstep(0.42, 0.5, streakPhase) * (1.0 - smoothstep(0.5, 0.58, streakPhase));

  // 3. Crinkle. Two out-of-phase sines beat against each other, which is enough
  // structure to read as creased foil without a noise texture.
  float crinkle = sin(uv.x * 130.0 + sin(uv.y * 61.0) * 2.7) * 0.5 + 0.5;

  half strength = half(clamp(intensity, 0.0, 1.0));

  half3 result = mix(base, base * 0.42h + rainbow * 0.78h, strength);
  result += half3(half(streak) * 0.5h * strength);
  result += half3((half(crinkle) - 0.5h) * 0.07h * strength);

  return half4(clamp(result, 0.0h, 1.0h) * alpha, alpha);
}
