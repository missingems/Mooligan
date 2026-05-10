import SwiftUI

public extension View {
  @ViewBuilder
  func listRowVerticalInsets(
    top: CGFloat = 0,
    bottom: CGFloat = 0
  ) -> some View {
    self.listRowInsets(.top, top)
      .listRowInsets(.bottom, bottom)
  }
}

public extension View {
  /// Applies horizontal padding that matches UIKit's `systemMinimumLayoutMargins`
  /// (16pt on standard iPhones, 20pt on Plus/Max/iPad).
  @MainActor func adaptiveHorizontalPadding() -> some View {
    self.padding(.horizontal, systemHorizontalMargin)
  }
}

@MainActor public var systemHorizontalMargin: CGFloat {
#if os(iOS)
  guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first(where: { $0.isKeyWindow }),
        let rootVC = window.rootViewController else {
    return 16 // Fallback
  }
  // Access the margins from the root UIViewController
  return rootVC.systemMinimumLayoutMargins.leading
#else
  return 16
#endif
}
