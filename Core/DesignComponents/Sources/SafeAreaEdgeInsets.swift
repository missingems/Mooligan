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
