import DesignComponents
import SwiftUI
import VariableBlur

extension View {
  func edgeScrims() -> some View {
    self
      .overlay(alignment: .bottom) {
        ZStack {
          VariableBlurView(maxBlurRadius: 2.0, direction: .blurredBottomClearTop, startOffset: 0)
          LinearGradient(
            colors: [.clear, DesignComponentsAsset.invertedPrimary.swiftUIColor.opacity(0.62)],
            startPoint: .top,
            endPoint: .bottom
          )
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .frame(height: 20)
      }
      .overlay(alignment: .top) {
        ZStack {
          VariableBlurView(maxBlurRadius: 2.0, direction: .blurredTopClearBottom, startOffset: 0)
          LinearGradient(
            colors: [DesignComponentsAsset.invertedPrimary.swiftUIColor.opacity(0.62), .clear],
            startPoint: .top,
            endPoint: .bottom
          )
        }
        .ignoresSafeArea(.all, edges: .top)
        .frame(height: 20)
      }
  }
}
