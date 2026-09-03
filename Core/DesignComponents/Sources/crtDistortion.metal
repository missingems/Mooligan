//
//  crtDistortion.metal
//  DesignComponents
//
//  Created by Jun on 3/9/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 crtDistortion(float2 position, SwiftUI::Layer layer, float2 bounds, float time, half4 bgColor) {
  // 1. Prevent division by zero if bounds aren't resolved yet
  if (bounds.x <= 0.0 || bounds.y <= 0.0) {
    return layer.sample(position);
  }
  
  // 2. Normalize coordinates and center them
  float2 uv = position / bounds;
  float2 crtUV = uv * 2.0 - 1.0;
  
  // 3. Apply barrel curvature (bulging screen)
  float curvature = dot(crtUV, crtUV) * 0.15;
  crtUV = crtUV * (1.0 + curvature);
  
  // 4. Zoom in slightly to prevent sampling outside the original bounds
  crtUV *= 0.85;
  
  // Convert back to 0..1 space
  crtUV = crtUV * 0.5 + 0.5;
  
  // Mask out pixels that fall outside the curved screen
  if (crtUV.x < 0.0 || crtUV.x > 1.0 || crtUV.y < 0.0 || crtUV.y > 1.0) {
    return bgColor;
  }
  
  float2 samplePos = crtUV * bounds;
  
  // 5. Chromatic Aberration (RGB shift)
  float shift = 1.5 + sin(time * 5.0) * 0.5;
  
  half r = layer.sample(samplePos + float2(shift, 0.0)).r;
  half g = layer.sample(samplePos).g;
  half b = layer.sample(samplePos + float2(-shift, 0.0)).b;
  half a = layer.sample(samplePos).a;
  
  // 6. Scanlines
  float scanline = sin(samplePos.y * 1.5 - time * 10.0) * 0.08;
  
  // 7. Vignette & Edge Fade Combined
  // A. The radial vignette heavily rounds off the corners
  float2 centered = crtUV * 2.0 - 1.0;
  float cornerFade = 1.0 - smoothstep(0.5, 1.4, dot(centered, centered));
  
  // B. The edge fade ensures the flat sides, top, and bottom perfectly blend out
  float fadeX = smoothstep(0.0, 0.12, min(crtUV.x, 1.0 - crtUV.x));
  float fadeY = smoothstep(0.0, 0.12, min(crtUV.y, 1.0 - crtUV.y));
  
  // Multiply them to get a soft rectangular mask with heavily rounded corners
  float finalFade = fadeX * fadeY * cornerFade;
  
  // Combine effects
  half3 crtColor = half3(r, g, b) - half3(scanline);
  
  // Smoothly blend the CRT image into the background color
  return mix(bgColor, half4(crtColor, a), finalFade);
}
