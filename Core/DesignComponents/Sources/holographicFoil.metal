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
///   2. one bright specular streak that travels across the surface;
///   3. a fine crinkle, so the surface reads as plastic rather than glass.
///
/// `time` is a slow clock, and it is the only thing that moves the sheen. An
/// earlier version also took the device's roll from Core Motion, so the foil
/// caught the light as the phone turned — which sounds right and, on a screen
/// you are already holding still to read, mostly read as the card twitching.
[[ stitchable ]] half4 holographicFoil(
  float2 position,
  half4 color,
  float2 bounds,
  float time,
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
  float sweep = (uv.x * 0.75 + uv.y * 0.45) + time * 0.09;

  // 1. Interference bands.
  float band = sweep * 14.0;
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

  // Modulated, not replaced. Mixing the art down towards a flat rainbow was
  // what made a foil card read as washed out rather than shiny: it threw away
  // the contrast the art depends on. Tinting the art with the interference
  // field instead keeps every edge in the illustration and lets the colour sit
  // on top of it, which is what a real foil does to the ink underneath.
  half3 tinted = base * (0.72h + 0.62h * rainbow);
  half3 result = mix(base, tinted, strength);

  // The specular streak stays additive — it is light on the surface rather
  // than a property of the ink.
  result += half3(half(streak) * 0.42h * strength);
  result += half3((half(crinkle) - 0.5h) * 0.06h * strength);

  return half4(clamp(result, 0.0h, 1.0h) * alpha, alpha);
}
