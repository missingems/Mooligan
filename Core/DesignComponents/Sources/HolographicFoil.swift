import CoreMotion
import SwiftUI

/// Publishes device roll, so foil surfaces catch the light as the phone moves.
///
/// One shared monitor with a subscriber count: a screen full of foil cards
/// spins up a single `CMMotionManager` rather than one per card. Silently
/// reports a flat zero on hardware without a gyroscope, and on the simulator.
@MainActor
@Observable
public final class DeviceTiltMonitor {
  public static let shared = DeviceTiltMonitor()

  /// Device roll in radians, clamped to a comfortable viewing range.
  public private(set) var tilt: Double = 0

  @ObservationIgnored private let motionManager = CMMotionManager()
  @ObservationIgnored private var subscribers = 0

  private init() {}

  public func subscribe() {
    subscribers += 1
    guard subscribers == 1, motionManager.isDeviceMotionAvailable else { return }

    motionManager.deviceMotionUpdateInterval = 1 / 30
    motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
      guard let motion else { return }
      let roll = motion.attitude.roll + motion.attitude.pitch * 0.35
      self?.tilt = min(max(roll, -1.2), 1.2)
    }
  }

  public func unsubscribe() {
    subscribers = max(0, subscribers - 1)
    guard subscribers == 0 else { return }
    motionManager.stopDeviceMotionUpdates()
  }
}

/// Overlays the `holographicFoil` shader on whatever it is attached to.
///
/// Applied to the wrapper it makes a booster look like printed foil; applied at
/// a lower `intensity` to a card image it reads as a traditional foil pull.
public struct HolographicFoilModifier: ViewModifier {
  private let intensity: Double
  private let isAnimated: Bool

  @State private var tiltMonitor = DeviceTiltMonitor.shared
  @State private var size: CGSize = .zero

  public init(intensity: Double, isAnimated: Bool) {
    self.intensity = intensity
    self.isAnimated = isAnimated
  }

  public func body(content: Content) -> some View {
    TimelineView(.animation(minimumInterval: 1 / 30, paused: isAnimated == false)) { context in
      let time = context.date.timeIntervalSinceReferenceDate

      content
        .colorEffect(
          ShaderLibrary.designComponents.holographicFoil(
            .float2(size),
            .float(time),
            .float(tiltMonitor.tilt),
            .float(intensity)
          )
        )
    }
    .onGeometryChange(for: CGSize.self, of: { $0.size }) { size = $0 }
    .onAppear { tiltMonitor.subscribe() }
    .onDisappear { tiltMonitor.unsubscribe() }
  }
}

public extension View {
  /// - Parameters:
  ///   - intensity: `0` leaves the view untouched, `1` is full wrapper foil.
  ///     Around `0.35` is right for a foil card, where the art still has to read.
  ///   - isAnimated: pause the clock for views that are off screen or static.
  func holographicFoil(intensity: Double = 1, isAnimated: Bool = true) -> some View {
    modifier(HolographicFoilModifier(intensity: intensity, isAnimated: isAnimated))
  }
}
