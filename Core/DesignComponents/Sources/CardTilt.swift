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
    let isTracking = DeviceTilt.isTracking(isActive: isActive, scenePhase: scenePhase, reduceMotion: reduceMotion)
    let angles = Self.angles(tilt: isTracking ? DeviceTilt.shared.offset : .zero, pose: pose, range: range)

    content
      .rotation3DEffect(.degrees(angles.pitch), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
      .rotation3DEffect(.degrees(angles.yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
      .task(id: isTracking) {
        guard isTracking else { return }
        await DeviceTilt.shared.track()
      }
  }

  /// Degrees about the x axis and the y axis. The phone's lean is held to `range` and the pose goes
  /// on top, so a finger can still carry the card further than the phone can.
  nonisolated static func angles(tilt: CGPoint, pose: CGPoint, range: Double) -> (pitch: Double, yaw: Double) {
    (
      pitch: min(max(Double(tilt.y) * 30, -range), range) + Double(pose.y),
      yaw: min(max(-Double(tilt.x) * 30, -range), range) + Double(pose.x)
    )
  }
}
