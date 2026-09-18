import CoreGraphics
import CoreMotion
import Observation
import SwiftUI
import UIKit

@MainActor @Observable
public final class DeviceTilt {
  public static let shared = DeviceTilt()

  /// `state.offset` again, as the one property views observe: `state` changes on every sample, this
  /// only when the lean has moved far enough to see.
  public private(set) var offset: CGPoint = .zero
  @ObservationIgnored private let manager = CMMotionManager()
  @ObservationIgnored private(set) var state = DeviceTiltState()

  /// Whether a view follows the phone: only while it asks to, while the app is in front, and never
  /// with Reduce Motion on.
  public nonisolated static func isTracking(isActive: Bool, scenePhase: ScenePhase, reduceMotion: Bool) -> Bool {
    isActive && scenePhase == .active && reduceMotion == false
  }

  public func track() async {
    if state.addViewer(), manager.isDeviceMotionAvailable {
      manager.deviceMotionUpdateInterval = 1 / 60
      manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
        guard let gravity = motion?.gravity else { return }
        MainActor.assumeIsolated {
          self?.receive(x: gravity.x, y: gravity.y)
        }
      }
    }

    while Task.isCancelled == false {
      try? await Task.sleep(for: .seconds(3600))
    }

    if state.removeViewer() {
      manager.stopDeviceMotionUpdates()
      offset = .zero
    }
  }

  private func receive(x: Double, y: Double) {
    guard state.viewers > 0 else { return }
    let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.effectiveGeometry.interfaceOrientation
    if state.receive(DeviceTiltState.gravity(x: x, y: y, in: orientation)) {
      offset = state.offset
    }
  }
}
