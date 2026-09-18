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

  /// Whether a piece of `cardId`'s page stays out of sight while the hover card lands on it. The
  /// card goes for the whole landing, since the flying card stands in for it. With `untilPageShown`,
  /// the rest of the page waits only until the flight starts, so it fades in as the card arrives.
  func hidesLanding(of cardId: UUID, untilPageShown: Bool = false) -> Bool {
    isLanding && self.cardId == cardId && (untilPageShown == false || isPageHidden)
  }

  /// A transform card keeps its id when it turns over, so the face has to match as well.
  func isShowing(_ cardId: UUID, image: DisplayableCardImage?) -> Bool {
    self.cardId == cardId && self.image == image
  }

  /// Puts `card` on the hover card. Left alone when it is already there, since the strip asks again
  /// on every step of a scrub.
  func show(_ card: CardDetailFeature.State) {
    guard isShowing(card.id, image: card.displayableCardImage) == false else { return }
    image = card.displayableCardImage
    isLandscape = card.content.card.isLandscape
    isFoil = card.content.card.availableFoilness == true
    cardId = card.id
  }

  /// Hands the page over from `outgoing`, the card the pager is on, to the one already shown. The
  /// outgoing card is drawn where the page had it, over its own backdrop, and the landing page stays
  /// hidden until it has built.
  func beginLanding(from outgoing: CardDetailFeature.State?) {
    self.outgoing = outgoing?.displayableCardImage
    outgoingIsLandscape = outgoing?.content.card.isLandscape == true
    outgoingIsFoil = outgoing?.content.card.availableFoilness == true
    outgoingFrame = cardFrame
    landingBackdrop = outgoing?.backdropURL
    isOutgoingHidden = false
    pageReadyId = nil
    isPageHidden = true
    isLanding = true
  }

  /// Returns once the landing page has hidden its pieces, which it reports through `pageReadyId`, so
  /// the page swaps before anything moves. Gives up after 14 polls in case the page never reports.
  func waitForPage(_ id: UUID, clock: any Clock<Duration> = ContinuousClock()) async {
    for _ in 0..<14 {
      if pageReadyId == id { break }
      try? await clock.sleep(for: .milliseconds(8))
    }
  }

  func fingerDown(at location: CGPoint, velocity: CGFloat?) {
    releaseVelocity = 0
    fingerMoved(to: location, velocity: velocity)
  }

  func fingerMoved(to location: CGPoint, velocity: CGFloat?) {
    self.location = location
    self.velocity = velocity ?? 0
  }

  /// Kept for the strip to read when it starts to coast: this and the scroll view's own phase
  /// change come from the same lift, in either order.
  func fingerLifted(velocity: CGFloat?) {
    releaseVelocity = velocity ?? self.velocity
    self.velocity = 0
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
