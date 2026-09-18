import Foundation
import Networking
import Observation

@MainActor @Observable
public final class CarouselScrub {
  var cardId: UUID?
  var selectedId: UUID?
  var pageReadyId: UUID?
  var image: DisplayableCardImage?
  var isLandscape = false
  var isFoil = false
  var landingBackdrop: URL?
  var location: CGPoint = .zero
  var velocity: CGFloat = 0
  var releaseVelocity: CGFloat = 0
  var carouselFrame: CGRect = .zero
  var pageFrame: CGRect = .zero
  var cardFrame: CGRect = .zero
  var restingCardFrame: CGRect = .zero
  var outgoing: DisplayableCardImage?
  var outgoingIsLandscape = false
  var outgoingIsFoil = false
  var outgoingFrame: CGRect = .zero
  var isOutgoingHidden = false
  var isLightAppearance = false
  var isHovering = false
  var isLanding = false
  var isFlying = false
  var isPageHidden = false
  @ObservationIgnored var landing: Task<Void, Never>?

  public init() {}

  var isSettledUntracked: Bool {
    _isHovering == false && _isLanding == false
  }

  func waitUntilSettled() async {
    guard isSettledUntracked == false else { return }
    for await isSettled in Observations({ self.isHovering == false && self.isLanding == false }) where isSettled {
      return
    }
  }

  func endLanding() {
    isLanding = false
    isFlying = false
    isPageHidden = false
    outgoing = nil
    landingBackdrop = nil
    pageReadyId = nil
    landing?.cancel()
    landing = nil
  }
}
