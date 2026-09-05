@testable import DesignComponents
import CoreGraphics
import Foundation
import Testing
import UIKit

struct ArtCropImageProcessorTests {
  private func makeImage(width: Int, height: Int) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, 1)
    UIColor.red.setFill()
    UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }

  @Test func whenCroppingACardImage_shouldReturnTheArtWindow() throws {
    let processor = ArtCropImageProcessor()
    let image = makeImage(width: 488, height: 680)

    let result = try #require(processor.process(image))
    let cgImage = try #require(result.cgImage)

    // The crop rect is expanded to whole pixels, so allow a pixel of slack either way.
    let box = ArtCropImageProcessor.standardArtBox
    #expect(abs(CGFloat(cgImage.width) - box.width * 488) <= 2)
    #expect(abs(CGFloat(cgImage.height) - box.height * 680) <= 2)
  }

  @Test func whenCropping_shouldProduceASmallerImageThanTheSource() throws {
    let processor = ArtCropImageProcessor()
    let image = makeImage(width: 488, height: 680)

    let result = try #require(processor.process(image))
    let cgImage = try #require(result.cgImage)

    #expect(cgImage.width < 488)
    #expect(cgImage.height < 680)
  }

  @Test func whenCroppingWithACustomBox_shouldHonourIt() throws {
    let processor = ArtCropImageProcessor(
      artBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
    )
    let image = makeImage(width: 400, height: 600)

    let result = try #require(processor.process(image))
    let cgImage = try #require(result.cgImage)

    #expect(cgImage.width == 200)
    #expect(cgImage.height == 300)
  }

  @Test func whenBoxExceedsTheImage_shouldClampToTheImageBounds() throws {
    let processor = ArtCropImageProcessor(
      artBox: CGRect(x: 0.5, y: 0.5, width: 2, height: 2)
    )
    let image = makeImage(width: 400, height: 600)

    let result = try #require(processor.process(image))
    let cgImage = try #require(result.cgImage)

    #expect(cgImage.width <= 400)
    #expect(cgImage.height <= 600)
  }

  @Test func whenBoxIsEmpty_shouldFallBackToTheOriginalImage() throws {
    let processor = ArtCropImageProcessor(artBox: .zero)
    let image = makeImage(width: 400, height: 600)

    let result = try #require(processor.process(image))
    let cgImage = try #require(result.cgImage)

    #expect(cgImage.width == 400)
    #expect(cgImage.height == 600)
  }

  @Test func whenBoxesDiffer_shouldNotShareACacheIdentifier() {
    // The identifier is Nuke's cache key, so two crops must not collide.
    let standard = ArtCropImageProcessor()
    let custom = ArtCropImageProcessor(artBox: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))

    #expect(standard.identifier != custom.identifier)
  }

  @Test func whenBoxesMatch_shouldShareACacheIdentifier() {
    #expect(ArtCropImageProcessor().identifier == ArtCropImageProcessor().identifier)
  }
}
