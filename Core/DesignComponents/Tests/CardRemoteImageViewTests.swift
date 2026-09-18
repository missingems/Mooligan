@testable import DesignComponents
import CoreGraphics
import Nuke
import Testing

@MainActor struct CardRemoteImageViewTests {
  private func identifiers(
    isLandscape: Bool = false,
    isTransformed: Bool = false,
    downsampleWidth: CGFloat? = nil
  ) -> [String] {
    CardRemoteImageView.processors(
      isLandscape: isLandscape,
      isTransformed: isTransformed,
      downsampleWidth: downsampleWidth
    )
    .map { $0.identifier }
  }

  @Test func withoutADownsampleWidth_theImageShouldNotBeResized() {
    let rotation = RotationImageProcessor(degrees: 90).identifier
    let flip = FlipImageProcessor().identifier

    #expect(identifiers().isEmpty)
    #expect(identifiers(isLandscape: true, isTransformed: true) == [rotation, flip])
  }

  @Test func aDownsampledImage_shouldBeResizedBeforeItIsTurnedOrFlipped() {
    let resize = ImageProcessors.Resize(width: 31.5).identifier
    let rotation = RotationImageProcessor(degrees: 90).identifier
    let flip = FlipImageProcessor().identifier

    #expect(identifiers(isLandscape: true, isTransformed: true, downsampleWidth: 31.5) == [resize, rotation, flip])
  }

  /// The processors' identifiers are part of Nuke's cache key, so a thumbnail must not be served
  /// where the full-size card was asked for.
  @Test func differentDownsampleWidths_shouldNotShareACacheEntry() {
    let thumbnail = identifiers(downsampleWidth: 31.5)

    #expect(thumbnail != identifiers(downsampleWidth: 63))
    #expect(thumbnail != identifiers())
  }
}
