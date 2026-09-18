import SwiftUI

/// What the strip does when its scroll phase changes, or `nil` for nothing.
enum CarouselScrollResponse: Equatable, Sendable {
  case beginScrub
  case land
  case landOnceSettled
  case recentre

  init?(
    phase: ScrollPhase,
    isHovering: Bool,
    isLanding: Bool,
    velocity: CGFloat,
    releaseVelocity: CGFloat,
    isCentredOnSelection: Bool
  ) {
    if phase == .interacting {
      self = .beginScrub
    } else if phase == .decelerating, isHovering, max(abs(velocity), abs(releaseVelocity)) < 120 {
      // Let go of a still strip and the card goes at once, rather than waiting out the snap.
      // Anything with a throw in it skips this and lands from `.idle` below, once it has run out.
      // The speed is the finger's, from the tracker: the phase change's own velocity arrived
      // empty on a fast release, read as zero, and landed the card the finger had just left.
      self = .land
    } else if phase == .idle, isHovering {
      self = .landOnceSettled
    } else if phase == .idle, isLanding == false, isCentredOnSelection == false {
      self = .recentre
    } else {
      return nil
    }
  }
}
