@testable import CardDetail
import DesignComponents
import Foundation
import Testing

/// The card at the top of a page. The scrub's hover card lands on it at this size too, so a change
/// here moves both.
struct CardLayoutConfigurationDetailPageTests {
  @Test func whenUpright_shouldTakeTwoThirdsOfThePage() {
    let configuration = CardLayoutConfiguration.detailPage(isLandscape: false, pageWidth: 402)

    #expect(configuration.rotation == .portrait)
    #expect(configuration.size == CGSize(width: 268, height: 374))
  }

  @Test func whenOnItsSide_shouldTakeFiveSixthsOfThePage() {
    let configuration = CardLayoutConfiguration.detailPage(isLandscape: true, pageWidth: 402)

    #expect(configuration.rotation == .landscape)
    #expect(configuration.size == CGSize(width: 335, height: 240))
  }

  @Test func whenThePageDoesNotDivideEvenly_shouldRoundToAWholePoint() {
    #expect(CardLayoutConfiguration.detailPage(isLandscape: false, pageWidth: 440).size == CGSize(width: 293, height: 409))
    #expect(CardLayoutConfiguration.detailPage(isLandscape: true, pageWidth: 440).size == CGSize(width: 367, height: 263))
  }
}
