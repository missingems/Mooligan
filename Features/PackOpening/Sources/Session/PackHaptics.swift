import CoreHaptics
import SwiftUI
import UIKit

/// Physical feedback for the pack's two drag interactions: tearing it open,
/// and dragging each card into view.
///
/// Both get a continuous, roughening rumble that tracks the finger rather than
/// a canned pattern, with a sharp transient every time progress crosses a
/// notch. Falls back to `UIImpactFeedbackGenerator` wherever Core Haptics is
/// unavailable.
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

  /// Starts the continuous rumble. Call when a drag begins.
  func beginRumble() {
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

  /// Drives the rumble's intensity and fires a click each time progress crosses
  /// a notch, so the feedback tracks the finger rather than a timer.
  func updateRumble(progress: Double) {
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
  func cancelRumble() {
    try? tearPlayer?.stop(atTime: CHHapticTimeImmediate)
    tearPlayer = nil
    lastNotch = 0
  }

  /// The drag commits: the pack gives way, or a card lands face up.
  func completeRumble() {
    cancelRumble()
    notification.notificationOccurred(.success)
  }

  /// The drag has carried the card far enough that letting go will send it
  /// away. A light tick here is what lets the threshold be felt rather than
  /// guessed at, which is most of why a swipe stops feeling vague.
  func swipeThresholdCrossed() {
    impact.impactOccurred(intensity: 0.55)
  }

  /// A card turning over. Heavier for the pulls worth caring about.
  func reveal(isHit: Bool) {
    UIImpactFeedbackGenerator(style: isHit ? .heavy : .soft).impactOccurred()
  }
}
