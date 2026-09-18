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
      scrub.fingerDown(
        at: context.converter.location(in: .global),
        velocity: context.converter.velocity(in: .global)?.x
      )

    case .changed:
      scrub.fingerMoved(
        to: context.converter.location(in: .global),
        velocity: context.converter.velocity(in: .global)?.x
      )

    default:
      scrub.fingerLifted(velocity: context.converter.velocity(in: .global)?.x)
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
