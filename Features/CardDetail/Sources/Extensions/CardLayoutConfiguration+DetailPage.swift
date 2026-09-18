import DesignComponents
import Foundation

extension CardLayoutConfiguration {
  /// The card at the top of a card's page, which the scrub's hover card also flies into, so the two
  /// have to come out the same size.
  static func detailPage(isLandscape: Bool, pageWidth: CGFloat) -> CardLayoutConfiguration {
    CardLayoutConfiguration(
      rotation: isLandscape ? .landscape : .portrait,
      maxWidth: ((isLandscape ? 2.5 : 2.0) / 3.0 * pageWidth).rounded()
    )
  }
}
