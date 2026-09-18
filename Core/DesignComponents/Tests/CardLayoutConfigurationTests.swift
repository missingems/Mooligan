@testable import DesignComponents
import CoreGraphics
import Testing

struct CardLayoutConfigurationTests {
  @Test func aPortraitCard_shouldTakeItsHeightFromTheCardRatioToTheNearestPoint() {
    #expect(CardLayoutConfiguration(rotation: .portrait, maxWidth: 100).size == CGSize(width: 100, height: 140))
    #expect(CardLayoutConfiguration(rotation: .portrait, maxWidth: 160).size == CGSize(width: 160, height: 223))
    #expect(CardLayoutConfiguration(rotation: .portrait, maxWidth: 375).size == CGSize(width: 375, height: 524))
    #expect(CardLayoutConfiguration(rotation: .portrait, maxWidth: 402).size == CGSize(width: 402, height: 562))
  }

  @Test func aLandscapeCard_shouldBeShorterThanItIsWide() {
    #expect(CardLayoutConfiguration(rotation: .landscape, maxWidth: 100).size == CGSize(width: 100, height: 72))
    #expect(CardLayoutConfiguration(rotation: .landscape, maxWidth: 200).size == CGSize(width: 200, height: 143))
    #expect(CardLayoutConfiguration(rotation: .landscape, maxWidth: 375).size == CGSize(width: 375, height: 268))
    #expect(CardLayoutConfiguration(rotation: .landscape, maxWidth: 402).size == CGSize(width: 402, height: 288))
  }

  @Test func aPortraitCardsCorners_shouldBeFivePercentOfItsWidth() {
    #expect(abs(CardLayoutConfiguration(rotation: .portrait, maxWidth: 100).cornerRadius - 5) < 0.0001)
    #expect(abs(CardLayoutConfiguration(rotation: .portrait, maxWidth: 375).cornerRadius - 18.75) < 0.0001)
  }

  /// Turned on its side, the card's short edge is its height, and the corners follow the short edge
  /// either way.
  @Test func aLandscapeCardsCorners_shouldBeFivePercentOfItsHeight() {
    #expect(abs(CardLayoutConfiguration(rotation: .landscape, maxWidth: 200).cornerRadius - 7.15) < 0.0001)
    #expect(abs(CardLayoutConfiguration(rotation: .landscape, maxWidth: 402).cornerRadius - 14.4) < 0.0001)
  }

  @Test func eachRotation_shouldUseTheRatioThatTurnsItsWidthIntoItsHeight() {
    #expect(CardLayoutConfiguration.Rotation.portrait.ratio == MagicCardImageRatio.widthToHeight.rawValue)
    #expect(CardLayoutConfiguration.Rotation.landscape.ratio == MagicCardImageRatio.heightToWidth.rawValue)
  }

  @Test func configurations_shouldBeEqualOnlyWhenBuiltAlike() {
    let configuration = CardLayoutConfiguration(rotation: .portrait, maxWidth: 160)

    #expect(configuration == CardLayoutConfiguration(rotation: .portrait, maxWidth: 160))
    #expect(configuration != CardLayoutConfiguration(rotation: .landscape, maxWidth: 160))
    #expect(configuration != CardLayoutConfiguration(rotation: .portrait, maxWidth: 161))
  }
}
