import SwiftUI
import VariableBlur

extension View {
  func edgeScrims() -> some View {
    overlay(alignment: .bottom) {
      VariableBlurView(maxBlurRadius: 2.0, direction: .blurredBottomClearTop, startOffset: 0)
        .ignoresSafeArea(.all, edges: .bottom)
        .frame(height: 20)
        .allowsHitTesting(false)
    }
    // Blur only. The tint this used to carry was the dark band across the top of the page.
    .overlay(alignment: .top) {
      VariableBlurView(maxBlurRadius: 2.0, direction: .blurredTopClearBottom, startOffset: 0)
        .ignoresSafeArea(.all, edges: .top)
        .frame(height: 20)
        .allowsHitTesting(false)
    }
  }
}
