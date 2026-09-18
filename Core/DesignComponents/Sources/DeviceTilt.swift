import CoreGraphics
import CoreMotion
import Observation
import UIKit

@MainActor @Observable
public final class DeviceTilt {
  public static let shared = DeviceTilt()

  public private(set) var offset: CGPoint = .zero
  @ObservationIgnored private let manager = CMMotionManager()
  @ObservationIgnored private var viewers = 0
  @ObservationIgnored private var smoothed: CGPoint = .zero
  @ObservationIgnored private var neutral: CGPoint?

  public func track() async {
    viewers += 1
    if viewers == 1, manager.isDeviceMotionAvailable {
      neutral = nil
      smoothed = .zero
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

    viewers -= 1
    if viewers == 0 {
      manager.stopDeviceMotionUpdates()
      offset = .zero
    }
  }

  private func receive(x deviceX: Double, y deviceY: Double) {
    guard viewers > 0 else { return }
    let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.effectiveGeometry.interfaceOrientation
    let (x, y) = switch orientation {
    case .landscapeRight: (-deviceY, deviceX)
    case .landscapeLeft: (deviceY, -deviceX)
    case .portraitUpsideDown: (-deviceX, -deviceY)
    default: (deviceX, deviceY)
    }
    let rest = neutral ?? CGPoint(x: x, y: y)
    neutral = CGPoint(x: rest.x + (x - rest.x) * 0.01, y: rest.y + (y - rest.y) * 0.01)
    smoothed = CGPoint(
      x: smoothed.x + (x - rest.x - smoothed.x) * 0.25,
      y: smoothed.y + (y - rest.y - smoothed.y) * 0.25
    )

    if abs(smoothed.x - offset.x) > 0.004 || abs(smoothed.y - offset.y) > 0.004 {
      offset = smoothed
    }
  }
}
