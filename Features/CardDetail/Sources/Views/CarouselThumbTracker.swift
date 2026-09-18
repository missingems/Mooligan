import SwiftUI
import UIKit

struct CarouselThumbTracker: UIGestureRecognizerRepresentable {
  let scrub: CarouselScrub

  func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
    Coordinator()
  }

  func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
    let recognizer = UIPanGestureRecognizer()
    recognizer.cancelsTouchesInView = false
    recognizer.delaysTouchesBegan = false
    recognizer.delaysTouchesEnded = false
    recognizer.delegate = context.coordinator
    return recognizer
  }

  func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
    switch recognizer.state {
    case .began:
      scrub.releaseVelocity = 0
      scrub.location = context.converter.location(in: .global)
      scrub.velocity = context.converter.velocity(in: .global)?.x ?? 0

    case .changed:
      scrub.location = context.converter.location(in: .global)
      scrub.velocity = context.converter.velocity(in: .global)?.x ?? 0

    default:
      // Kept for the strip to read when it starts to coast: this and the scroll view's own phase
      // change come from the same lift, in either order.
      scrub.releaseVelocity = context.converter.velocity(in: .global)?.x ?? scrub.velocity
      scrub.velocity = 0
    }
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      true
    }
  }
}
