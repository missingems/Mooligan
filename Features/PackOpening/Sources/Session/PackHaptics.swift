import CoreHaptics
import SwiftUI
import UIKit

/// Physical feedback for the tear.
///
/// The tear is the one interaction in the app where haptics carry most of the
/// realism, so it gets a Core Haptics engine rather than the canned impact
/// generators: a continuous, roughening rumble while plastic is giving way, and
/// a sharp transient every time the tear jumps a notch. Falls back to
/// `UIImpactFeedbackGenerator` wherever Core Haptics is unavailable.
@MainActor
final class PackHaptics {
  private var engine: CHHapticEngine?
  private var tearPlayer: CHHapticAdvancedPatternPlayer?
  private let impact = UIImpactFeedbackGenerator(style: .light)
  private let notification = UINotificationFeedbackGenerator()

  private var lastNotch = 0

  /// How many discrete clicks the full tear is divided into.
  private static let notchCount = 22

  init() {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

    engine = try? CHHapticEngine()
    engine?.playsHapticsOnly = true
    engine?.isAutoShutdownEnabled = true
    try? engine?.start()
  }

  func prepare() {
    impact.prepare()
    notification.prepare()
    lastNotch = 0
  }

  /// Starts the continuous rumble. Call when the drag begins.
  func beginTear() {
    guard let engine else { return }

    let event = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4),
      ],
      relativeTime: 0,
      duration: 8
    )

    guard let pattern = try? CHHapticPattern(events: [event], parameters: []) else { return }
    tearPlayer = try? engine.makeAdvancedPlayer(with: pattern)
    try? tearPlayer?.start(atTime: CHHapticTimeImmediate)
  }

  /// Drives the rumble's intensity and fires a click each time the tear crosses
  /// a notch, so the feedback tracks the finger rather than a timer.
  func updateTear(progress: Double) {
    let clamped = min(max(progress, 0), 1)

    if let tearPlayer {
      let parameters = [
        CHHapticDynamicParameter(
          parameterID: .hapticIntensityControl,
          value: Float(0.2 + clamped * 0.8),
          relativeTime: 0
        ),
        CHHapticDynamicParameter(
          parameterID: .hapticSharpnessControl,
          value: Float(0.3 + clamped * 0.7),
          relativeTime: 0
        ),
      ]
      try? tearPlayer.sendParameters(parameters, atTime: CHHapticTimeImmediate)
    }

    let notch = Int(clamped * Double(Self.notchCount))
    guard notch != lastNotch else { return }
    lastNotch = notch

    if engine == nil {
      impact.impactOccurred(intensity: 0.3 + clamped * 0.7)
    }
  }

  /// Stops the rumble without the success thump — the drag was abandoned.
  func cancelTear() {
    try? tearPlayer?.stop(atTime: CHHapticTimeImmediate)
    tearPlayer = nil
    lastNotch = 0
  }

  /// The pack gives way.
  func completeTear() {
    cancelTear()
    notification.notificationOccurred(.success)
  }

  /// A card turning over. Heavier for the pulls worth caring about.
  func reveal(isHit: Bool) {
    UIImpactFeedbackGenerator(style: isHit ? .heavy : .soft).impactOccurred()
  }
}
