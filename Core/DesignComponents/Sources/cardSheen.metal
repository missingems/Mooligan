#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 cardSheen(float2 position, half4 color, float2 bounds, float2 tilt) {
  if (bounds.x <= 0.0 || bounds.y <= 0.0) {
    return half4(0.0h);
  }

  float radius = 0.05 * min(bounds.x, bounds.y);
  float2 corner = abs(position - bounds * 0.5) - (bounds * 0.5 - radius);
  float edge = length(max(corner, 0.0)) + min(max(corner.x, corner.y), 0.0) - radius;
  half coverage = half(clamp(0.5 - edge, 0.0, 1.0));
  if (coverage <= 0.0h) {
    return half4(0.0h);
  }

  float2 uv = position / bounds;
  float2 light = float2(0.5, 0.5) + float2(tilt.x, -tilt.y) * 2.2;
  float across = dot(uv - light, normalize(float2(1.0, 0.62)));
  half glare = half(exp(-across * across / 0.09)) * 0.11h + half(exp(-across * across / 0.012)) * 0.06h;
  return half4(glare, glare, glare, glare) * coverage;
}
