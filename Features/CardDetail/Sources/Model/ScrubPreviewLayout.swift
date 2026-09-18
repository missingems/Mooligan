import DesignComponents
import Foundation

/// Where the scrub's floating card sits and how large it is in each of its three places: shrunk
/// onto the glass, hovering above the bar, and landed on the page.
struct ScrubPreviewLayout: Equatable, Sendable {
  let configuration: CardLayoutConfiguration
  let hoverScale: CGFloat
  let thumbnailScale: CGFloat
  let hoverCenter: CGPoint
  let thumbnailCenter: CGPoint
  let pageCardCenter: CGPoint
  let carousel: CGRect

  init(page: CGRect, carousel: CGRect, isLandscape: Bool) {
    configuration = .detailPage(isLandscape: isLandscape, pageWidth: page.width)
    let size = configuration.size
    hoverScale = (isLandscape ? 244.0 : 183.0) / size.width
    thumbnailScale = 34.0 / size.height
    hoverCenter = CGPoint(x: carousel.midX, y: carousel.minY - 14 - size.height * hoverScale / 2)
    thumbnailCenter = CGPoint(x: carousel.midX, y: carousel.midY)
    // Where the page lays its card out while it sits at its top, below the page's 13pt of padding.
    pageCardCenter = CGPoint(x: page.midX, y: page.minY + 13 + size.height / 2)
    self.carousel = carousel
  }

  /// The page's own measure of its card once it has one, else where the card would be.
  func landedCenter(restingCardFrame: CGRect) -> CGPoint {
    restingCardFrame.width > 0
      ? CGPoint(x: restingCardFrame.midX, y: restingCardFrame.midY)
      : pageCardCenter
  }

  /// A quarter of the finger's way off the bar's centre, held to a short reach either way.
  func follow(_ location: CGPoint) -> CGSize {
    CGSize(
      width: min(max((location.x - carousel.midX) * 0.25, -24), 24),
      height: min(max((location.y - carousel.midY) * 0.25, -8), 8)
    )
  }

  static func lean(forVelocity velocity: CGFloat) -> CGFloat {
    min(max(velocity / 90, -16), 16)
  }
}
