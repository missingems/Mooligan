import SwiftUI
import UIKit

final class ChartScrubRecognizer: UIGestureRecognizer {
  var onChange: (([CGFloat]) -> Void)?

  private let rule = ScrubPressRule.standard
  private var origin: CGPoint?
  private var tracked: [UITouch] = []
  private var pressTimer: Timer?

  override init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)
    cancelsTouchesInView = false
    delaysTouchesBegan = false
    delaysTouchesEnded = false
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesBegan(touches, with: event)
    for touch in touches where tracked.contains(touch) == false {
      tracked.append(touch)
    }

    guard state == .possible else {
      evaluate()
      return
    }
    guard tracked.count == 1, let view, let first = tracked.first else {
      fail()
      return
    }

    origin = first.location(in: view)
    pressTimer?.invalidate()
    pressTimer = Timer.scheduledTimer(withTimeInterval: rule.minimumPressDuration, repeats: false) { [weak self] _ in
      MainActor.assumeIsolated { self?.activate() }
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesMoved(touches, with: event)
    evaluate()
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesEnded(touches, with: event)
    tracked.removeAll { touches.contains($0) }
    evaluate()
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    super.touchesCancelled(touches, with: event)
    tracked.removeAll { touches.contains($0) }
    evaluate()
  }

  override func reset() {
    super.reset()
    pressTimer?.invalidate()
    pressTimer = nil
    tracked.removeAll()
    origin = nil
    onChange?([])
  }

  private func activate() {
    pressTimer = nil
    guard state == .possible, tracked.count == 1, let view, let first = tracked.first else { return }
    state = .began
    onChange?([first.location(in: view).x])
  }

  private func fail() {
    pressTimer?.invalidate()
    pressTimer = nil
    state = .failed
    onChange?([])
  }

  private func evaluate() {
    guard let view else { return }
    let locations = tracked.map { $0.location(in: view) }

    switch state {
    case .possible:
      guard let origin, let point = locations.first, locations.count == 1 else {
        fail()
        return
      }
      if rule.hasDrifted(from: origin, to: point) {
        fail()
      }

    case .began, .changed:
      if locations.isEmpty {
        state = .ended
        onChange?([])
      } else if locations.count >= 2 {
        state = .cancelled
        onChange?([])
      } else {
        state = .changed
        onChange?(locations.map(\.x))
      }

    default:
      break
    }
  }
}
