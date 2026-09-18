import SwiftUI

public struct CardTilt: ViewModifier {
  private let isActive: Bool
  private let pose: CGPoint
  private let range: Double
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  public init(isActive: Bool = true, pose: CGPoint = .zero, range: Double = 6) {
    self.isActive = isActive
    self.pose = pose
    self.range = range
  }

  public func body(content: Content) -> some View {
    let isTracking = isActive && scenePhase == .active && reduceMotion == false
    let tilt = isTracking ? DeviceTilt.shared.offset : .zero

    content
      .rotation3DEffect(.degrees(min(max(tilt.y * 30, -range), range) + pose.y), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
      .rotation3DEffect(.degrees(min(max(-tilt.x * 30, -range), range) + pose.x), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
      .task(id: isTracking) {
        guard isTracking else { return }
        await DeviceTilt.shared.track()
      }
  }
}
