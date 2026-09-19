import SwiftUI

extension EnvironmentValues {
  /// How far a floating badge has swayed, in degrees, for the reflection on it to follow. Zero for
  /// anything that is not floating.
  @Entry var hoverPose: CGPoint = .zero
}
